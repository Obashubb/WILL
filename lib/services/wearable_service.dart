import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/ble_constants.dart';
import '../models/health_sample.dart';
import 'inference_service.dart';
import 'insights_repository.dart';
import 'notification_service.dart';
import 'profile_service.dart';
import 'samples_repository.dart';

enum WearableConnectionState {
  idle,
  scanning,
  connecting,
  connected,
  disconnected,
  error,
}

class WearableService extends GetxController {
  // Public reactive state ---------------------------------------------------

  final Rx<WearableConnectionState> connectionState =
      WearableConnectionState.idle.obs;
  final Rxn<HealthSample> latestSample = Rxn<HealthSample>();
  final RxString deviceName = ''.obs;
  final RxnString lastError = RxnString();
  final RxBool needsAppSettings = false.obs;
  final Rx<InsightResult> currentInsight = const InsightResult(
    InsightLabel.normal,
    ConditionLabel.none,
  ).obs;
  final Rxn<HealthSample> displaySample = Rxn<HealthSample>();

  /// Every device the most recent scan turned up. Sorted by RSSI (strongest
  /// first) and de-duplicated by remoteId. UI lists this directly.
  final RxList<ScanResult> discoveredDevices = <ScanResult>[].obs;

  /// Wall-clock time the last successful sample arrived. Drives "Updated 3s
  /// ago" affordances across the app.
  final Rxn<DateTime> lastSampleAt = Rxn<DateTime>();

  /// Whether the OS Bluetooth adapter is on/off/unauthorized. UI uses this
  /// to swap the "turn on Bluetooth" card in for the device list.
  final Rxn<BluetoothAdapterState> adapterState = Rxn<BluetoothAdapterState>();

  // Internal state ----------------------------------------------------------

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<BluetoothConnectionState>? _deviceConnSub;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _readingsChar;
  BluetoothCharacteristic? _commandsChar;
  StreamSubscription<List<int>>? _notifySub;
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastDisplay = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastAlert = DateTime.fromMillisecondsSinceEpoch(0);

  // Auto-reconnect backoff ladder. Walks forward each failed attempt; resets
  // on a successful reconnect or when the user manually stops.
  static const _reconnectLadder = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 60),
    Duration(seconds: 60),
  ];
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _userStopped = false;

  @override
  void onInit() {
    super.onInit();
    // Watch the OS Bluetooth adapter. If the user turns BT off, the UI
    // reacts; if they turn it back on after a previous "BT off" error,
    // we resume scanning automatically.
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      adapterState.value = state;
      if (state == BluetoothAdapterState.on &&
          connectionState.value == WearableConnectionState.error &&
          (lastError.value?.contains('Bluetooth is off') ?? false)) {
        lastError.value = null;
        // Best-effort silent restart; user can also tap "Scan" themselves.
        startPairing();
      }
    });
  }

  @override
  void onClose() {
    _adapterSub?.cancel();
    _teardown();
    super.onClose();
  }

  // Public API --------------------------------------------------------------

  /// Kicks off pairing. Begins a BLE scan and exposes every nearby device
  /// via [discoveredDevices]; the sheet renders that list directly.
  Future<void> startPairing() async {
    lastError.value = null;
    needsAppSettings.value = false;
    _userStopped = false;
    await _startReal();
  }

  /// Connects to a device the user picked from the nearby list. Reuses the
  /// same connection path as the auto-connect-on-single-Will-match flow.
  Future<void> connectTo(BluetoothDevice device) async {
    _userStopped = false;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSub?.cancel();
    _scanSub = null;
    await _connect(device);
  }

  Future<void> stop() async {
    _userStopped = true;
    _clearReconnect();
    discoveredDevices.clear();
    _teardown();
    connectionState.value = WearableConnectionState.idle;
  }

  Future<bool> sendCommand(WearableCommand cmd) async {
    final char = _commandsChar;
    if (char == null) return false;
    try {
      await char.write([cmd.opcode], withoutResponse: false);
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    }
  }

  /// Opens the OS settings page for this app so the user can re-enable
  /// Bluetooth permission after a permanent denial.
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  /// Single funnel for every new sample: live UI, last-seen, recent-history
  /// cache, and upload queue all get the same value.
  void _publish(HealthSample sample) {
    latestSample.value = sample;
    lastSampleAt.value = sample.timestamp;
    SamplesRepository.appendRecent(sample);
    SamplesRepository.enqueuePending(sample);

    // Dashboard display, show first reading instantly, then every 5s.
    final nowD = DateTime.now();
    if (displaySample.value == null ||
        nowD.difference(_lastDisplay).inSeconds >= 5) {
      _lastDisplay = nowD;
      displaySample.value = sample;
    }

    // Motion-gated, throttled inference.
    final now = DateTime.now();
    const motionThreshold = 0.6;
    if (now.difference(_lastInference).inSeconds >= 30 &&
        sample.motion <= motionThreshold) {
      _lastInference = now;
      final inference = Get.find<InferenceService>();
      final result = inference.classify(sample);
      currentInsight.value = result;
      // Transition-aware persister: stores when the label changes or as a
      // 5-minute heartbeat. Drives the Insights History screen.
      InsightsRepository.recordIfMeaningful(result, sample);

      if (result.severity == InsightLabel.alert) {
        _maybeAlert(result);
      }
    }
  }

  // Real BLE ----------------------------------------------------------------

  Future<void> _startReal() async {
    if (Platform.isAndroid) {
      final result = await _ensureAndroidPermissions();
      if (result == _PermResult.permanentlyDenied) {
        _setError(
          'Bluetooth access is blocked. Open Settings to enable it.',
          needsSettings: true,
        );
        return;
      }
      if (result == _PermResult.denied) {
        _setError('Bluetooth permission was denied. Please try again.');
        return;
      }
    }

    if (!await FlutterBluePlus.isSupported) {
      _setError('This device does not support Bluetooth Low Energy.');
      return;
    }

    final adapter = await FlutterBluePlus.adapterState.first.timeout(
      const Duration(seconds: 1),
      onTimeout: () => BluetoothAdapterState.unknown,
    );
    adapterState.value = adapter;
    if (adapter != BluetoothAdapterState.on) {
      _setError('Bluetooth is off. Please turn it on, then try again.');
      return;
    }

    connectionState.value = WearableConnectionState.scanning;
    discoveredDevices.clear();

    try {
      // No service filter: we want every nearby device so the user can see
      // what's around, even when their band is misconfigured or off. The
      // sheet pins Will Band candidates to the top of the list.
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
    } catch (_) {
      _setError("Couldn't start scanning. Please try again.");
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      _mergeScanResults(results);

      // Auto-connect on the common case: exactly one Will Band in range and
      // the user hasn't picked something else yet. Multiple candidates leave
      // the choice to the user.
      if (connectionState.value != WearableConnectionState.scanning) return;
      final willMatches = results.where(_looksLikeWillBand).toList();
      if (willMatches.length == 1) {
        final hit = willMatches.single;
        try {
          await FlutterBluePlus.stopScan();
        } catch (_) {}
        await _scanSub?.cancel();
        _scanSub = null;
        await _connect(hit.device);
      }
    });

    // After the scan finishes naturally, surface a friendly hint if we
    // never saw a Will Band candidate. The device list stays visible.
    Future<void>.delayed(const Duration(seconds: 31), () {
      if (connectionState.value != WearableConnectionState.scanning) return;
      final hasWill = discoveredDevices.any(_looksLikeWillBand);
      if (!hasWill) {
        _setError(
          "We didn't see your Will Band nearby. Make sure it's powered on, "
          'or pick a device from the list to try anyway.',
        );
      } else {
        // Multiple Will-name candidates — keep the list visible, return to idle.
        connectionState.value = WearableConnectionState.idle;
      }
    });
  }

  void _mergeScanResults(List<ScanResult> results) {
    final byId = <String, ScanResult>{
      for (final r in discoveredDevices) r.device.remoteId.str: r,
    };
    for (final r in results) {
      // Skip totally unnamed devices to keep the list scannable.
      final name = r.device.advName.isNotEmpty
          ? r.device.advName
          : r.advertisementData.advName;
      if (name.isEmpty) continue;
      byId[r.device.remoteId.str] = r;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    discoveredDevices.assignAll(merged);
  }

  bool _looksLikeWillBand(ScanResult r) {
    final name = r.device.advName.isNotEmpty
        ? r.device.advName
        : r.advertisementData.advName;
    if (name == WillBle.advertisedName) return true;
    final lowerName = name.toLowerCase();
    if (lowerName.contains('will')) return true;
    final hasUuid = r.advertisementData.serviceUuids
        .map((g) => g.toString().toLowerCase())
        .contains(WillBle.serviceUuid.toLowerCase());
    return hasUuid;
  }

  Future<void> _connect(BluetoothDevice device) async {
    connectionState.value = WearableConnectionState.connecting;
    _device = device;
    deviceName.value = device.advName.isNotEmpty
        ? device.advName
        : WillBle.advertisedName;
    final tag = device.remoteId.str;
    _log('[$tag] connect: starting');

    // Phase 1 — open the GATT connection. Android occasionally returns
    // "GATT error 133" on the first attempt; one retry recovers the bulk
    // of those cases without bothering the user.
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        await device.connect(
          license: License.free,
          timeout: const Duration(seconds: 10),
        );
        _log('[$tag] connect: device.connect returned (attempt $attempt)');
        break;
      } catch (e) {
        _log('[$tag] connect: device.connect FAILED (attempt $attempt): $e');
        if (attempt < 2 && _isTransientConnectError(e)) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          continue;
        }
        _setError(_connectErrorMessage(e));
        return;
      }
    }

    // Phase 2 — wait for the connectionState stream to actually report
    // "connected". iOS discoverServices fails if called before the
    // connection has fully settled.
    try {
      await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));
      _log('[$tag] connect: connectionState reached connected');
    } catch (e) {
      _log('[$tag] connect: settle FAILED: $e');
      _setError(
        'Your band connected but disconnected right away. '
        'Reset it (power off then on) and try again.',
      );
      try {
        await device.disconnect();
      } catch (_) {}
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Phase 3 — service discovery + characteristic lookup. Use orElse so
    // a stray non-Will device doesn't blow up with a StateError.
    final BluetoothService? service;
    try {
      final services = await device.discoverServices();
      _log(
        '[$tag] connect: discovered ${services.length} services: '
        '${services.map((s) => s.uuid.toString()).join(", ")}',
      );
      service = services.cast<BluetoothService?>().firstWhere(
            (s) =>
                s?.uuid.toString().toLowerCase() ==
                WillBle.serviceUuid.toLowerCase(),
            orElse: () => null,
          );
    } catch (e) {
      _log('[$tag] connect: discoverServices FAILED: $e');
      _setError(
        'Connected, but couldn\'t read the band\'s services. '
        'Reset the band (power off then on) and pair again.',
      );
      try {
        await device.disconnect();
      } catch (_) {}
      return;
    }
    if (service == null) {
      _log('[$tag] connect: Will service UUID not found on device');
      _setError(
        "This device isn't running the Will Band firmware "
        '(or it has a different service id). Make sure you picked the right one.',
      );
      try {
        await device.disconnect();
      } catch (_) {}
      return;
    }

    final readings = service.characteristics.cast<BluetoothCharacteristic?>().firstWhere(
          (c) =>
              c?.uuid.toString().toLowerCase() ==
              WillBle.readingsCharacteristicUuid.toLowerCase(),
          orElse: () => null,
        );
    final commands = service.characteristics.cast<BluetoothCharacteristic?>().firstWhere(
          (c) =>
              c?.uuid.toString().toLowerCase() ==
              WillBle.commandsCharacteristicUuid.toLowerCase(),
          orElse: () => null,
        );
    if (readings == null || commands == null) {
      _log(
        '[$tag] connect: missing characteristic '
        '(readings=${readings != null}, commands=${commands != null})',
      );
      _setError(
        "The band's firmware doesn't expose the expected channels. "
        "It may need a firmware update.",
      );
      try {
        await device.disconnect();
      } catch (_) {}
      return;
    }
    _readingsChar = readings;
    _commandsChar = commands;

    // Phase 4 — subscribe to notifications and we're live.
    try {
      await _readingsChar!.setNotifyValue(true);
      _notifySub = _readingsChar!.lastValueStream.listen(_decodeReading);
      _log('[$tag] connect: notifications subscribed');
    } catch (e) {
      _log('[$tag] connect: setNotifyValue FAILED: $e');
      _setError(
        "Couldn't subscribe to the band's data stream. Try pairing again.",
      );
      try {
        await device.disconnect();
      } catch (_) {}
      return;
    }

    await ProfileService.setPairedDeviceId(device.remoteId.str);
    connectionState.value = WearableConnectionState.connected;
    _reconnectAttempt = 0;
    _watchConnectionState(device);
    _log('[$tag] connect: SUCCESS');
  }

  static void _log(String message) {
    // Debug-mode only so the console isn't polluted in release builds.
    // Run `flutter logs` (or watch Xcode/Android Studio) while pairing
    // to see exactly which phase a problem device dies on.
    assert(() {
      debugPrint('WearableService $message');
      return true;
    }());
  }

  bool _isTransientConnectError(Object e) {
    final s = e.toString().toLowerCase();
    // Android's notorious GATT error 133, plus a couple of variants the
    // platform returns when the stack hiccups during initial handshake.
    return s.contains('133') ||
        s.contains('gatt error') ||
        s.contains('androidcode: 133');
  }

  String _connectErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('timeout')) {
      return 'The band took too long to respond. Move it closer and try again.';
    }
    if (s.contains('already connected')) {
      return 'The band is already connected. Try Disconnect first, then Pair.';
    }
    if (s.contains('not authorized') || s.contains('permission')) {
      return 'Bluetooth access was blocked. Check Settings → Will → Bluetooth.';
    }
    return "Couldn't connect to the band. Move it closer or reset it, then try again.";
  }

  void _watchConnectionState(BluetoothDevice device) {
    _deviceConnSub?.cancel();
    _deviceConnSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if (_userStopped) return;
        connectionState.value = WearableConnectionState.disconnected;
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    if (_userStopped) return;
    if (_reconnectAttempt >= _reconnectLadder.length) {
      _setError(
        "We can't reach your band right now. Pull up the band sheet to try again.",
      );
      return;
    }
    final wait = _reconnectLadder[_reconnectAttempt];
    _reconnectAttempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(wait, _attemptReconnect);
  }

  Future<void> _attemptReconnect() async {
    if (_userStopped) return;
    final device = _device;
    if (device == null) return;
    connectionState.value = WearableConnectionState.connecting;
    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 8),
      );
      // Some firmwares need a re-discover after dropping. Cheap, idempotent.
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) =>
            s.uuid.toString().toLowerCase() ==
            WillBle.serviceUuid.toLowerCase(),
        orElse: () => services.first,
      );
      _readingsChar = service.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() ==
            WillBle.readingsCharacteristicUuid.toLowerCase(),
        orElse: () => service.characteristics.first,
      );
      await _readingsChar!.setNotifyValue(true);
      _notifySub?.cancel();
      _notifySub = _readingsChar!.lastValueStream.listen(_decodeReading);
      connectionState.value = WearableConnectionState.connected;
      _reconnectAttempt = 0;
    } catch (_) {
      // Move to the next backoff step.
      _scheduleReconnect();
    }
  }

  void _clearReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
  }

  void _decodeReading(List<int> bytes) {
    if (bytes.length < 20) return;
    final hr = bytes[0];
    final spo2 = bytes[1];
    final temp = ((bytes[3] << 8) | bytes[2]) / 100.0;
    final ax = ((bytes[5] << 8) | bytes[4]).toSigned(16);
    final ay = ((bytes[7] << 8) | bytes[6]).toSigned(16);
    final az = ((bytes[9] << 8) | bytes[8]).toSigned(16);
    final steps = (bytes[15] << 8) | bytes[14];
    final pi = ((bytes[17] << 8) | bytes[16]) / 100.0;
    final hrv = (bytes[19] << 8) | bytes[18];
    final motion = (sqrt(ax * ax + ay * ay + az * az) / 16384.0).clamp(
      0.0,
      1.0,
    );

    _publish(
      HealthSample(
        heartRate: hr,
        spo2: spo2,
        temperature: double.parse(temp.toStringAsFixed(1)),
        motion: double.parse(motion.toStringAsFixed(2)),
        stepcount: steps,
        perfusionIndex: pi,
        hrv: hrv,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<_PermResult> _ensureAndroidPermissions() async {
    // Android 12+ (API 31+) needs BLUETOOTH_SCAN + BLUETOOTH_CONNECT.
    // Android 11 and below uses the legacy BLUETOOTH perms + ACCESS_FINE_LOCATION
    // (declared in the manifest with maxSdkVersion="30"). Requesting
    // locationWhenInUse here is a no-op on Android 12+ thanks to the
    // neverForLocation flag on BLUETOOTH_SCAN, and is required on Android 11.
    final statuses = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      return _PermResult.permanentlyDenied;
    }
    if (statuses.values.every((s) => s.isGranted || s.isLimited)) {
      return _PermResult.granted;
    }
    return _PermResult.denied;
  }

  void _setError(String message, {bool needsSettings = false}) {
    connectionState.value = WearableConnectionState.error;
    lastError.value = message;
    needsAppSettings.value = needsSettings;
  }

  void _teardown() {
    _notifySub?.cancel();
    _notifySub = null;
    _scanSub?.cancel();
    _scanSub = null;
    _deviceConnSub?.cancel();
    _deviceConnSub = null;
    _clearReconnect();
    try {
      _device?.disconnect();
    } catch (_) {}
    _device = null;
    _readingsChar = null;
    _commandsChar = null;
    lastSampleAt.value = null;
    displaySample.value = null;
  }

  void _maybeAlert(InsightResult result) {
    final now = DateTime.now();
    if (now.difference(_lastAlert).inMinutes < 5) return;
    _lastAlert = now;

    final notifications = Get.find<NotificationService>();
    notifications.showAlert(
      'Health alert',
      'Your vitals need attention. Please rest and check the app.',
    );
  }
}

enum _PermResult { granted, denied, permanentlyDenied }

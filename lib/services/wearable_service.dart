import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/ble_constants.dart';
import '../models/health_sample.dart';
import 'notification_service.dart';
import 'profile_service.dart';
import 'samples_repository.dart';
import 'inference_service.dart';

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

  /// Mock mode is on while the hardware is still being built. Toggle off
  /// when the firmware is flashed and a real Will Band is in range.
  final RxBool mockMode = false.obs;

  // Internal state ----------------------------------------------------------

  Timer? _mockTimer;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<BluetoothConnectionState>? _deviceConnSub;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _readingsChar;
  BluetoothCharacteristic? _commandsChar;
  StreamSubscription<List<int>>? _notifySub;
  final Random _rng = Random();
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

  /// Kicks off pairing. In mock mode this spins up the periodic sample
  /// emitter; in real mode it begins a BLE scan and exposes every nearby
  /// device via [discoveredDevices].
  Future<void> startPairing() async {
    lastError.value = null;
    needsAppSettings.value = false;
    _userStopped = false;
    if (mockMode.value) {
      await _startMock();
      return;
    }
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

  /// Toggles demo mode and reflects the change in connection state right
  /// away. Turning demo on starts mock samples; turning it off stops them.
  Future<void> setMockMode(bool enabled) async {
    if (mockMode.value == enabled) return;
    mockMode.value = enabled;
    await stop();
    if (enabled) {
      await startPairing();
    }
  }

  Future<void> stop() async {
    _userStopped = true;
    _clearReconnect();
    discoveredDevices.clear();
    _teardown();
    connectionState.value = WearableConnectionState.idle;
  }

  Future<bool> sendCommand(WearableCommand cmd) async {
    if (mockMode.value) {
      // No-op for mock; pretend the command worked.
      return true;
    }
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

  // Mock --------------------------------------------------------------------

  Future<void> _startMock() async {
    connectionState.value = WearableConnectionState.scanning;
    deviceName.value = 'Mock Will Band';
    await Future<void>.delayed(const Duration(milliseconds: 800));
    connectionState.value = WearableConnectionState.connecting;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    connectionState.value = WearableConnectionState.connected;
    await ProfileService.setPairedDeviceId('mock-band-001');

    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) => _emitMock());
    _emitMock();
  }

  void _emitMock() {
    final prev = latestSample.value;

    final hrBase = prev?.heartRate ?? 78;
    final spo2Base = prev?.spo2 ?? 97;
    final tempBase = prev?.temperature ?? 36.7;

    final hr = (hrBase + _rng.nextInt(7) - 3).clamp(55, 110);
    final spo2 = (spo2Base + _rng.nextInt(3) - 1).clamp(93, 100);
    final temp = (tempBase + (_rng.nextDouble() - 0.5) * 0.1).clamp(36.2, 37.4);
    final stepcount = (prev?.stepcount ?? 0) + _rng.nextInt(5);
    final motion = _rng.nextDouble() * 0.4;

    _publish(
      HealthSample(
        heartRate: hr,
        spo2: spo2,
        temperature: double.parse(temp.toStringAsFixed(1)),
        motion: double.parse(motion.toStringAsFixed(2)),
        stepcount: stepcount,
        perfusionIndex: double.parse(
          (1 + _rng.nextDouble() * 3).toStringAsFixed(2),
        ),
        hrv: 20 + _rng.nextInt(40),
        timestamp: DateTime.now(),
      ),
    );
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
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
      );
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
    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 10),
      );
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) =>
            s.uuid.toString().toLowerCase() ==
            WillBle.serviceUuid.toLowerCase(),
      );
      _readingsChar = service.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() ==
            WillBle.readingsCharacteristicUuid.toLowerCase(),
      );
      _commandsChar = service.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() ==
            WillBle.commandsCharacteristicUuid.toLowerCase(),
      );
      await _readingsChar!.setNotifyValue(true);
      _notifySub = _readingsChar!.lastValueStream.listen(_decodeReading);
      await ProfileService.setPairedDeviceId(device.remoteId.str);
      connectionState.value = WearableConnectionState.connected;
      _reconnectAttempt = 0;
      _watchConnectionState(device);
    } catch (_) {
      _setError("Couldn't connect to your Will Band. Please try again.");
    }
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
    _mockTimer?.cancel();
    _mockTimer = null;
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

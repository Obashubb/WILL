import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
  final RxList<ScanResult> discoveredDevices = <ScanResult>[].obs;
  final Rxn<DateTime> lastSampleAt = Rxn<DateTime>();
  final Rxn<BluetoothAdapterState> adapterState = Rxn<BluetoothAdapterState>();

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
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      adapterState.value = state;
      if (state == BluetoothAdapterState.on &&
          connectionState.value == WearableConnectionState.error &&
          (lastError.value?.contains('Bluetooth is off') ?? false)) {
        lastError.value = null;
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

  Future<void> startPairing() async {
    lastError.value = null;
    needsAppSettings.value = false;
    _userStopped = false;
    await _startReal();
  }

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

  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  void _publish(HealthSample sample) {
    latestSample.value = sample;
    lastSampleAt.value = sample.timestamp;
    SamplesRepository.appendRecent(sample);
    SamplesRepository.enqueuePending(sample);

    final nowD = DateTime.now();
    if (displaySample.value == null ||
        nowD.difference(_lastDisplay).inSeconds >= 5) {
      _lastDisplay = nowD;
      displaySample.value = sample;
    }

    final now = DateTime.now();
    const motionThreshold = 0.6;
    if (now.difference(_lastInference).inSeconds >= 30 &&
        sample.motion <= motionThreshold) {
      _lastInference = now;
      final inference = Get.find<InferenceService>();
      final result = inference.classify(sample);
      currentInsight.value = result;
      InsightsRepository.recordIfMeaningful(result, sample);

      if (result.severity == InsightLabel.alert) {
        _maybeAlert(result);
      }
    }
  }

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
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
    } catch (_) {
      _setError("Couldn't start scanning. Please try again.");
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      _mergeScanResults(results);

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

    Future<void>.delayed(const Duration(seconds: 31), () {
      if (connectionState.value != WearableConnectionState.scanning) return;
      final hasWill = discoveredDevices.any(_looksLikeWillBand);
      if (!hasWill) {
        _setError(
          "We didn't see your Will Band nearby. Make sure it's powered on, "
          'or pick a device from the list to try anyway.',
        );
      } else {
        connectionState.value = WearableConnectionState.idle;
      }
    });
  }

  void _mergeScanResults(List<ScanResult> results) {
    final byId = <String, ScanResult>{
      for (final r in discoveredDevices) r.device.remoteId.str: r,
    };
    for (final r in results) {
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
      } catch (e, s) {
        _report('connect.phase1.gatt (attempt $attempt)', tag, e, s);
        if (attempt < 2 && _isTransientConnectError(e)) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          continue;
        }
        _setError(_connectErrorMessage(e));
        return;
      }
    }

    // iOS fails discoverServices if called before the connection has fully
    // settled — wait for the state stream to confirm connected, then a beat.
    try {
      await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));
      _log('[$tag] connect: connectionState reached connected');
    } catch (e, s) {
      _report('connect.phase2.settle', tag, e, s);
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
    } catch (e, s) {
      _report('connect.phase3.discover', tag, e, s);
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
      _report(
        'connect.phase3.missing_service',
        tag,
        StateError('Will service UUID not advertised by ${device.advName}'),
        StackTrace.current,
      );
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
      _report(
        'connect.phase3.missing_characteristic',
        tag,
        StateError(
          'readings=${readings != null}, commands=${commands != null}',
        ),
        StackTrace.current,
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

    try {
      await _readingsChar!.setNotifyValue(true);
      _notifySub = _readingsChar!.lastValueStream.listen(_decodeReading);
      _log('[$tag] connect: notifications subscribed');
    } catch (e, s) {
      _report('connect.phase4.notify', tag, e, s);
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
    assert(() {
      debugPrint('WearableService $message');
      return true;
    }());
  }

  static void _report(
    String reason,
    String deviceTag,
    Object error,
    StackTrace stack,
  ) {
    assert(() {
      debugPrint('WearableService[$reason] [$deviceTag] $error');
      return true;
    }());
    try {
      FirebaseCrashlytics.instance
        ..setCustomKey('ble.device', deviceTag)
        ..setCustomKey('ble.phase', reason)
        ..recordError(
          error,
          stack,
          reason: 'wearable: $reason',
          fatal: false,
        );
    } catch (_) {}
  }

  bool _isTransientConnectError(Object e) {
    final s = e.toString().toLowerCase();
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
    // locationWhenInUse required for Android <12; harmless on 12+ thanks to
    // neverForLocation on BLUETOOTH_SCAN in the manifest.
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

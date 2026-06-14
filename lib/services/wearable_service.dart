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

  /// Mock mode is on while the hardware is still being built. Toggle off
  /// when the firmware is flashed and a real Will Band is in range.
  final RxBool mockMode = false.obs;

  Timer? _mockTimer;
  StreamSubscription<List<ScanResult>>? _scanSub;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _readingsChar;
  BluetoothCharacteristic? _commandsChar;
  StreamSubscription<List<int>>? _notifySub;
  final Random _rng = Random();
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);
  final Rxn<HealthSample> displaySample = Rxn<HealthSample>();
  DateTime _lastDisplay = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastAlert = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void onClose() {
    _teardown();
    super.onClose();
  }

  /// Kicks off pairing — either generates mock samples or scans for the
  /// real Will Band, then subscribes to its notify characteristic.
  Future<void> startPairing() async {
    lastError.value = null;
    needsAppSettings.value = false;
    if (mockMode.value) {
      await _startMock();
      return;
    }
    await _startReal();
  }

  /// Opens the OS settings page for this app so the user can re-enable
  /// Bluetooth permission after a permanent denial.
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  Future<void> stop() async {
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

  // -- Mock --------------------------------------------------------------

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
    final stepcount =
        (prev?.stepcount ?? 0) + _rng.nextInt(5); // NEW — climbs over time
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
        ), // 1-4%
        hrv: 20 + _rng.nextInt(40), // 20-60 ms
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Single funnel for every new sample: live UI, recent-history cache,
  /// and upload queue all get the same value.
  void _publish(HealthSample sample) {
    latestSample.value = sample;
    SamplesRepository.appendRecent(sample);
    SamplesRepository.enqueuePending(sample);

    // Dashboard display — show first reading instantly, then every 5s.
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

      // Fire an alert notification when severity is critical.
      if (result.severity == InsightLabel.alert) {
        _maybeAlert(result);
      }
    }
  }

  // -- Real BLE ----------------------------------------------------------

  Future<void> _startReal() async {
    // On iOS, Core Bluetooth shows the system permission prompt the first time
    // we scan, driven by NSBluetoothAlwaysUsageDescription in Info.plist.
    // Android requires explicit runtime permissions.
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
    if (adapter != BluetoothAdapterState.on) {
      _setError('Bluetooth is off. Please turn it on, then try again.');
      return;
    }

    connectionState.value = WearableConnectionState.scanning;

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(WillBle.serviceUuid)],
        timeout: const Duration(seconds: 15),
      );
    } catch (_) {
      _setError("Couldn't start scanning. Please try again.");
      return;
    }

    var foundDevice = false;
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      if (results.isEmpty) return;
      final hit = results.firstWhere(
        (r) =>
            r.advertisementData.advName == WillBle.advertisedName ||
            r.advertisementData.serviceUuids
                .map((g) => g.toString().toLowerCase())
                .contains(WillBle.serviceUuid.toLowerCase()),
        orElse: () => results.first,
      );
      foundDevice = true;
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
      _scanSub = null;
      await _connect(hit.device);
    });

    // Surface a friendly message if the scan finished without finding the band.
    Future<void>.delayed(const Duration(seconds: 16), () {
      if (!foundDevice &&
          connectionState.value == WearableConnectionState.scanning) {
        _setError(
          "Couldn't find your Will Band nearby. Make sure it's powered on and close by.",
        );
      }
    });
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
    } catch (_) {
      _setError("Couldn't connect to your Will Band. Please try again.");
    }
  }

  void _decodeReading(List<int> bytes) {
    // Payload is now 20 bytes: hr, spo2, temp, ax, ay, az, ts, steps, pi, hrv.
    if (bytes.length < 20) return;
    final hr = bytes[0];
    final spo2 = bytes[1];
    final temp = ((bytes[3] << 8) | bytes[2]) / 100.0;
    final ax = ((bytes[5] << 8) | bytes[4]).toSigned(16);
    final ay = ((bytes[7] << 8) | bytes[6]).toSigned(16);
    final az = ((bytes[9] << 8) | bytes[8]).toSigned(16);
    final steps = (bytes[15] << 8) | bytes[14];
    final pi = ((bytes[17] << 8) | bytes[16]) / 100.0; // PI was sent ×100
    final hrv = (bytes[19] << 8) | bytes[18]; // HRV in ms
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
        perfusionIndex: pi, // NEW
        hrv: hrv, // NEW
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
    try {
      _device?.disconnect();
    } catch (_) {}
    _device = null;
    _readingsChar = null;
    _commandsChar = null;
  }

  void _maybeAlert(InsightResult result) {
    // Only alert at most once every 5 minutes to avoid spamming.
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

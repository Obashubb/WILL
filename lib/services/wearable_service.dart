import 'dart:async';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/ble_constants.dart';
import '../models/health_sample.dart';
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

/// Controls what kind of synthetic samples [WearableService] emits in mock
/// mode. Switch this from the Demo Data sheet to drive the Insights tab
/// through every label without needing real hardware.
enum MockScenario {
  normal('Normal'),
  stress('Stress'),
  dehydration('Dehydration'),
  abnormalOxygen('Low oxygen'),
  crisis('Crisis');

  const MockScenario(this.label);
  final String label;
}

class WearableService extends GetxController {
  final Rx<WearableConnectionState> connectionState =
      WearableConnectionState.idle.obs;
  final Rxn<HealthSample> latestSample = Rxn<HealthSample>();
  final RxString deviceName = ''.obs;
  final RxnString lastError = RxnString();

  /// Mock mode is on while the hardware is still being built. Toggle off
  /// when the firmware is flashed and a real Will Band is in range.
  final RxBool mockMode = true.obs;

  /// Active scenario when mock mode is on. Drives the parameter ranges
  /// inside [_emitMock].
  final Rx<MockScenario> mockScenario = MockScenario.normal.obs;

  Timer? _mockTimer;
  StreamSubscription<List<ScanResult>>? _scanSub;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _readingsChar;
  BluetoothCharacteristic? _commandsChar;
  StreamSubscription<List<int>>? _notifySub;
  final Random _rng = Random();

  @override
  void onClose() {
    _teardown();
    super.onClose();
  }

  /// Kicks off pairing, either generates mock samples or scans for the
  /// real Will Band, then subscribes to its notify characteristic.
  Future<void> startPairing() async {
    lastError.value = null;
    if (mockMode.value) {
      await _startMock();
      return;
    }
    await _startReal();
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
    final spec = _scenarioSpec(mockScenario.value);
    final hr = (spec.hrCenter + _rng.nextInt(spec.hrJitter * 2 + 1) - spec.hrJitter)
        .clamp(45, 160);
    final spo2 = (spec.spo2Center + _rng.nextInt(spec.spo2Jitter * 2 + 1) - spec.spo2Jitter)
        .clamp(80, 100);
    final temp = (spec.tempCenter + (_rng.nextDouble() - 0.5) * spec.tempJitter)
        .clamp(35.0, 39.0);
    final motion = (spec.motionFloor +
            _rng.nextDouble() * (spec.motionCeil - spec.motionFloor))
        .clamp(0.0, 1.0);

    _publish(HealthSample(
      heartRate: hr,
      spo2: spo2,
      temperature: double.parse(temp.toStringAsFixed(1)),
      motion: double.parse(motion.toStringAsFixed(2)),
      timestamp: DateTime.now(),
    ));
  }

  _ScenarioSpec _scenarioSpec(MockScenario s) {
    switch (s) {
      case MockScenario.normal:
        return const _ScenarioSpec(
          hrCenter: 76, hrJitter: 5,
          spo2Center: 97, spo2Jitter: 1,
          tempCenter: 36.7, tempJitter: 0.2,
          motionFloor: 0.0, motionCeil: 0.3,
        );
      case MockScenario.stress:
        return const _ScenarioSpec(
          hrCenter: 110, hrJitter: 6,
          spo2Center: 96, spo2Jitter: 1,
          tempCenter: 36.9, tempJitter: 0.2,
          motionFloor: 0.0, motionCeil: 0.05,
        );
      case MockScenario.dehydration:
        return const _ScenarioSpec(
          hrCenter: 95, hrJitter: 4,
          spo2Center: 96, spo2Jitter: 1,
          tempCenter: 37.5, tempJitter: 0.3,
          motionFloor: 0.0, motionCeil: 0.04,
        );
      case MockScenario.abnormalOxygen:
        return const _ScenarioSpec(
          hrCenter: 96, hrJitter: 6,
          spo2Center: 90, spo2Jitter: 2,
          tempCenter: 36.9, tempJitter: 0.2,
          motionFloor: 0.0, motionCeil: 0.2,
        );
      case MockScenario.crisis:
        return const _ScenarioSpec(
          hrCenter: 122, hrJitter: 7,
          spo2Center: 88, spo2Jitter: 2,
          tempCenter: 38.0, tempJitter: 0.4,
          motionFloor: 0.0, motionCeil: 0.05,
        );
    }
  }

  /// Single funnel for every new sample: live UI, recent-history cache,
  /// and upload queue all get the same value.
  void _publish(HealthSample sample) {
    latestSample.value = sample;
    SamplesRepository.appendRecent(sample);
    SamplesRepository.enqueuePending(sample);
  }

  // -- Real BLE ----------------------------------------------------------

  Future<void> _startReal() async {
    final ok = await _ensurePermissions();
    if (!ok) {
      connectionState.value = WearableConnectionState.error;
      lastError.value = 'Bluetooth permission denied.';
      return;
    }
    if (!await FlutterBluePlus.isSupported) {
      connectionState.value = WearableConnectionState.error;
      lastError.value = 'This device does not support Bluetooth Low Energy.';
      return;
    }

    connectionState.value = WearableConnectionState.scanning;

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(WillBle.serviceUuid)],
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      connectionState.value = WearableConnectionState.error;
      lastError.value = 'Could not start scan: $e';
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      if (results.isEmpty) return;
      final hit = results.firstWhere(
        (r) => r.advertisementData.advName == WillBle.advertisedName ||
            r.advertisementData.serviceUuids
                .map((g) => g.toString().toLowerCase())
                .contains(WillBle.serviceUuid.toLowerCase()),
        orElse: () => results.first,
      );
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
      _scanSub = null;
      await _connect(hit.device);
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    connectionState.value = WearableConnectionState.connecting;
    _device = device;
    deviceName.value =
        device.advName.isNotEmpty ? device.advName : WillBle.advertisedName;
    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 10),
      );
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() ==
            WillBle.serviceUuid.toLowerCase(),
      );
      _readingsChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() ==
            WillBle.readingsCharacteristicUuid.toLowerCase(),
      );
      _commandsChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() ==
            WillBle.commandsCharacteristicUuid.toLowerCase(),
      );
      await _readingsChar!.setNotifyValue(true);
      _notifySub =
          _readingsChar!.lastValueStream.listen(_decodeReading);
      await ProfileService.setPairedDeviceId(device.remoteId.str);
      connectionState.value = WearableConnectionState.connected;
    } catch (e) {
      connectionState.value = WearableConnectionState.error;
      lastError.value = 'Failed to connect: $e';
    }
  }

  void _decodeReading(List<int> bytes) {
    // TODO(hardware): finalize the byte layout with the firmware engineer.
    // Expected: hr (u8), spo2 (u8), temp_x100 (i16 LE), ax (i16), ay (i16),
    // az (i16), ts (u32 LE). 14 bytes total.
    if (bytes.length < 14) return;
    final hr = bytes[0];
    final spo2 = bytes[1];
    final temp = ((bytes[3] << 8) | bytes[2]) / 100.0;
    final ax = ((bytes[5] << 8) | bytes[4]).toSigned(16);
    final ay = ((bytes[7] << 8) | bytes[6]).toSigned(16);
    final az = ((bytes[9] << 8) | bytes[8]).toSigned(16);
    final motion = (sqrt(ax * ax + ay * ay + az * az) / 16384.0).clamp(0.0, 1.0);

    _publish(HealthSample(
      heartRate: hr,
      spo2: spo2,
      temperature: double.parse(temp.toStringAsFixed(1)),
      motion: double.parse(motion.toStringAsFixed(2)),
      timestamp: DateTime.now(),
    ));
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
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
}

class _ScenarioSpec {
  const _ScenarioSpec({
    required this.hrCenter,
    required this.hrJitter,
    required this.spo2Center,
    required this.spo2Jitter,
    required this.tempCenter,
    required this.tempJitter,
    required this.motionFloor,
    required this.motionCeil,
  });
  final int hrCenter;
  final int hrJitter;
  final int spo2Center;
  final int spo2Jitter;
  final double tempCenter;
  final double tempJitter;
  final double motionFloor;
  final double motionCeil;
}

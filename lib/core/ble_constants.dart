/// BLE service and characteristic UUIDs for the Will wristband.
///
/// The hex prefix `57494c4c` is "WILL" in ASCII — kept that way to make it
/// easy to recognize on a sniffer. The firmware running on the ESP32-C3 MUST
/// expose exactly these UUIDs for the app to discover and bind to them.
///
/// TODO(hardware): keep the firmware in sync with these constants. If the
/// hardware engineer changes any of them, update here and in the firmware
/// at the same time.
class WillBle {
  WillBle._();

  /// Device name the wristband advertises.
  static const String advertisedName = 'Will Band';

  /// Primary GATT service hosted on the wristband.
  static const String serviceUuid = '57494c4c-0000-1000-8000-00805f9b34fb';

  /// Notify characteristic: streams the latest sample as packed bytes
  /// (hr | spo2 | temp_x100 | ax | ay | az | ts).
  static const String readingsCharacteristicUuid =
      '57494c4c-0001-1000-8000-00805f9b34fb';

  /// Read characteristic: battery percentage and firmware version.
  static const String deviceInfoCharacteristicUuid =
      '57494c4c-0002-1000-8000-00805f9b34fb';

  /// Write characteristic: short opcodes the app sends to the band
  /// (vibrate, set sample rate, recalibrate, etc.).
  static const String commandsCharacteristicUuid =
      '57494c4c-0003-1000-8000-00805f9b34fb';
}

/// Opcodes the phone can write to the commands characteristic.
enum WearableCommand {
  vibrate(0x01),
  recalibrate(0x02),
  setSampleRate(0x03);

  const WearableCommand(this.opcode);

  final int opcode;
}

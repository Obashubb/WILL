# Bluetooth (the band ↔ phone link)

## What it does

This is how the phone and the wristband talk to each other. The band reads heart rate, blood oxygen, body temperature, and motion, and sends them to the phone over **Bluetooth Low Energy (BLE)**. The phone can also send small commands back, for example, "vibrate now" when a reminder is due.

## How it works

Think of the wristband as a tiny mailbox with three slots:

| Slot (characteristic) | Direction | Used for |
|---|---|---|
| **Readings** | band → phone (push every 1-2 s) | One packed payload with all the live sensor values |
| **Device info** | phone reads on demand | Battery percent, firmware version |
| **Commands** | phone → band (write) | Short opcodes like *vibrate* or *recalibrate* |

The full conversation:

```
Phone                                  Wristband (ESP32-C3)
─────                                  ────────────────────
1.  Scan for advertised service UUID   ⇠ broadcasting "Will Band"
2.  Connect (GATT)                     → connection accepted
3.  Discover service + characteristics
4.  Subscribe to "Readings" notify     → band sends a packet every 2 s
5.  Decode bytes → HealthSample object
6.  (optional) Write to "Commands"     → band vibrates / changes rate
7.  Disconnect when user closes app
```

All identifiers (service + characteristic UUIDs, advertised device name) live in `lib/core/ble_constants.dart`. **The firmware MUST use exactly these UUIDs** or the app will not find the band.

## Why we built it this way

**Tradeoff 1, BLE vs. classic Bluetooth or Wi-Fi.** A wristband running off a small Li-Po battery has a strict energy budget. Classic Bluetooth and Wi-Fi drain the battery in hours. BLE was designed exactly for this, short bursts of data, sub-1 mA average current. The data we send (a few dozen bytes per second) fits easily.

**Tradeoff 2, one notify characteristic with packed bytes vs. one characteristic per metric.** A separate characteristic per metric is simpler to read in a debugger but burns more radio time (each one is its own packet). Packing heart rate, SpO₂, temperature, and motion into a single 14-byte payload gets all four updated for the cost of one BLE notification.

**Tradeoff 3, mock mode in the app.** The hardware engineer is still building the band. If the app had to wait for the firmware to compile before it could display a heart rate, UI work would block on hardware. Instead the `WearableService` ships with a *mock* generator that emits plausible samples on a timer. The dashboard treats them identically. When the real firmware is ready, we flip one boolean (`mockMode = false`) and the same screens render real data.

**Tradeoff 4, `flutter_blue_plus` vs. `flutter_reactive_ble`.** Both are good. `flutter_blue_plus` has more active development and a wider range of recent fixes. It is also the one the broader Flutter community defaults to.

## Why this fits our scope

- The PRD calls for BLE between the band and the phone. This is the standard implementation.
- The mock mode lets the project move forward in parallel with the hardware build.
- The same code that drives the mock also drives the real BLE, no rewrite needed when the band arrives.

## Example walkthrough

1. The user finishes signing up. The router redirects them to **Device Setup**.
2. They tap **Pair device**. `WearableService.startPairing()` is called.
3. If `mockMode` is on (default for now), the service simulates a scan (800 ms) and a connect (500 ms), then sets `connectionState = connected` and starts a periodic timer that emits a fake `HealthSample` every 2 seconds.
4. If `mockMode` is off (the real path):
   - The service asks for Bluetooth + location permissions through `permission_handler`.
   - It calls `FlutterBluePlus.startScan(withServices: [WillBle.serviceUuid])`.
   - The first matching device is selected. The service connects, discovers the GATT service, finds the Readings characteristic, calls `setNotifyValue(true)`, and subscribes to its `lastValueStream`.
   - Every notify packet runs through `_decodeReading()` which parses the 14 packed bytes into a `HealthSample`.
5. Either way, `latestSample` is a `Rxn<HealthSample>`, the Dashboard's `Obx` rebuilds and the four metric cards update instantly.

## Where to look

- `lib/core/ble_constants.dart`, service + characteristic UUIDs, advertised device name, command opcodes. The firmware mirrors these.
- `lib/services/wearable_service.dart`, the service. Holds `connectionState`, `latestSample`, `mockMode`, and both the mock generator and the real flutter_blue_plus flow.
- `lib/models/health_sample.dart`, the data shape the service produces.
- `lib/view/dashboard/dashboard_screen.dart`, subscribes to `latestSample` and the connection pill state.
- `lib/view/dashboard/metric_card.dart`, the four reusable HR / SpO₂ / Temp / Activity cards.
- `lib/view/onboarding/device_setup_screen.dart`, calls `startPairing()` and reflects the state.
- `android/app/src/main/AndroidManifest.xml`, BLE permissions for Android 12+ and the legacy Bluetooth/location ones for older Android.
- `ios/Runner/Info.plist`, `NSBluetoothAlwaysUsageDescription` so iOS shows the permission prompt.

## Further reading

- [Bluetooth Low Energy overview](https://developer.android.com/develop/connectivity/bluetooth/ble/ble-overview)
- [flutter_blue_plus on pub.dev](https://pub.dev/packages/flutter_blue_plus)
- [GATT characteristic types (notify, read, write)](https://www.bluetooth.com/specifications/specs/gatt-specification-supplement/)
- [ESP32 BLE peripheral examples (Arduino)](https://github.com/espressif/arduino-esp32/tree/master/libraries/BLE/examples), server-side reference for whoever flashes the band.

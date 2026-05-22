# Will

AI-based wearable monitoring app for sickle cell patients. The Flutter app pairs to an ESP32-C3 wristband over Bluetooth Low Energy, reads heart rate, blood oxygen, body temperature, and motion, runs a small on-device Random Forest to classify the user's current state, and surfaces insights, hydration tracking, and medication reminders.

- **Platforms**: Android and iOS
- **Bundle id**: `com.blessing.will`
- **Display name**: Will
- **Firebase project**: `will-wristband` (Auth + Firestore + local notifications channels)

## Getting started

### Prerequisites

- Flutter `3.44+` / Dart `3.10+`
- Xcode + iOS Simulator, or Android Studio + an Android emulator
- Firebase CLI (`npm i -g firebase-tools`) signed in with the project owner account
- Python 3.10+ if you intend to retrain the ML model (`pip install scikit-learn numpy`)

### Install

```bash
flutter pub get
flutter run            # picks up your connected device or emulator
```

The first launch will land on the Welcome screen. Sign up, sign in, or continue as guest. Either path leads through Device Setup before the Dashboard.

### Firebase

Auth and Firestore are pre-configured for `will-wristband`. If you ever need to refresh the platform configs:

```bash
flutterfire configure --project=will-wristband --platforms=android,ios --yes
```

To redeploy the Firestore security rules after editing `firestore.rules`:

```bash
firebase use will-wristband
firebase deploy --only firestore:rules
```

## Project map

| Folder | What lives there |
|---|---|
| `lib/core/` | Colors, theme, constants, router. |
| `lib/view/` | Every screen (auth, onboarding, dashboard, history, insights, care, profile) + shared widgets. |
| `lib/services/` | Long-running stuff: auth, wearable BLE, sync, inference, notifications, samples + care repos. |
| `lib/models/` | Data shapes (AppUser, HealthSample, Insight, Medication, HydrationEntry). |
| `assets/fonts/` | FormaDJR, full weight range. |
| `assets/ml/` | `model.json`, the on-device Random Forest. |
| `tools/` | `train_model.py`, sklearn script that regenerates the model. |
| `docs/` | Product requirements (academic + implementation). |
| `defense/` | Plain-English explainers for every major module. Start with `defense/README.md`. |

## Demoing and manual testing

Profile → **Demo data** opens a sheet that lets you switch the mock generator between scenarios (normal, stress, dehydration, low oxygen, crisis) and seed sample medications, hydration entries, and a few hours of history in one tap. See [`DEMO.md`](DEMO.md) for a 5-minute walkthrough that exercises every feature.

## Mock vs real

The wristband firmware is still being built. `WearableService.mockMode` defaults to `true`, the dashboard, history chart, and inference all run against a deterministic mock generator. Flip the flag (or wire it to a Profile toggle) when the firmware advertises the right service UUID and the byte layout in `_decodeReading()` matches.

## Building the ML model

```bash
# Optional: drop a labelled CSV at tools/data/samples.csv first.
python tools/train_model.py
```

The script reads the CSV if present, otherwise synthesizes class-conditional samples. It exports an updated `assets/ml/model.json` that the app picks up on next launch.

## Common gotchas

- **No location prompt on Android 11 and below**, BLE scanning needs location permission. The manifest already requests it conditionally.
- **iOS Bluetooth prompt**, the first time you open the app on a real device, iOS asks for Bluetooth permission. The strings in `Info.plist` explain why.
- **Test mode Firestore expired**, if writes start failing 30 days after the project was created, redeploy `firestore.rules`.
- **Notifications denied**, medications still save locally; the user just won't get the daily reminder. The system Settings app is where they can re-enable.

## License

Final-year project. Not for clinical use.

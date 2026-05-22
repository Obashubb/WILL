# WILL — Implementation PRD

> Companion to `PRD.md` (the academic / requirements doc). This document captures **what we are actually building, how, and in what order**. It supersedes the academic PRD wherever they conflict.

---

## 1. Product in one paragraph

WILL is a health-monitoring app for sickle cell patients. A wristband (ESP32-C3) reads vitals — heart rate, SpO₂, body temperature, motion — and streams them to a Flutter phone app over Bluetooth Low Energy. The phone shows live readings, keeps history, runs a small on-device ML model that flags abnormal patterns, reminds the user about water and medication, and backs everything up to Firebase. No server we maintain.

---

## 2. Confirmed decisions

| Decision | Value | Rationale |
|---|---|---|
| Platforms | Android + iOS | Flutter — both for free |
| App name | WILL | Package id stays `healthapp` for now |
| Firebase project id | `will-wristband` | Created under `wisdomiyamu@gmail.com` |
| State management | **GetX** (controllers + Rx + Obx only — no `GetMaterialApp`, no `Get.to`) | Lightweight reactive primitives without dragging in another router |
| Navigation | **`go_router`** with declarative redirect for the auth/onboarding gate | Decouples routing from state; same pattern as sigma_notes / syncc |
| Storage (cloud) | **Firebase** (Auth + Firestore + FCM) | No custom backend |
| Storage (local) | `get_storage` for KV, `flutter_secure_storage` for tokens | Already added |
| ML location | **On-device** (Random Forest) | Tiny model, offline, private |
| ML packaging | JSON-serialized trees, Dart evaluator | Simpler than TFLite for a Random Forest |
| BLE library | `flutter_blue_plus` | Most active community package |
| Typography | FormaDJR | Pulled from `sigma_notes` |
| Theme | Light | Calmer for a health context |
| UI philosophy | Simple, modern, functional | Information first; visuals quiet |
| Design skill | `/impeccable` (product register) | Translated to Flutter idioms |
| Tests | None for now | Re-add later if needed |

---

## 3. System architecture

```
┌────────────────────┐    BLE     ┌──────────────────────┐    HTTPS    ┌─────────────────┐
│   WILL Wristband   │ ◄────────► │     Flutter app      │ ◄─────────► │    Firebase     │
│   (ESP32-C3)       │  notify    │  (Android + iOS)     │   sync      │  Auth · FS · FCM│
│                    │  write     │                      │             │                 │
│  • MAX30102        │            │  • GetX state        │             │  users/{uid}/   │
│  • DS18B20         │            │  • BLE service       │             │   readings      │
│  • LIS3DH          │            │  • RF inference      │             │   insights      │
│  • Vibration motor │            │  • Local cache       │             │   medications   │
└────────────────────┘            └──────────────────────┘             └─────────────────┘
```

Three layers:

- **Edge** — ESP32-C3 reads sensors at ~1 Hz, packs them, exposes BLE characteristics.
- **Phone** — Flutter app does the heavy lifting: UI, history, inference, reminders, sync.
- **Cloud** — Firebase is a managed backup + auth + push provider. Not an inference server.

---

## 4. Tech stack

### Already in the project
- Flutter 3.44 / Dart 3.10
- `get`, `flutter_animate`, `sprung`, `intl`, `get_storage`, `path_provider`, `flutter_secure_storage`, `cupertino_icons`
- Local font: FormaDJR (all weights + italics)

### Added since Phase 2
- `firebase_core`, `firebase_auth`, `cloud_firestore` (Phase 2)
- `go_router` (Phase 2 refactor)
- `flutter_blue_plus`, `permission_handler` (Phase 3)
- `fl_chart` (Phase 4)
- `flutter_local_notifications`, `timezone`, `flutter_timezone` (Phase 6)

### To be added
| Package | Purpose | Phase |
|---|---|---|
| `firebase_messaging` | Push notifications (deferred — local notifications cover v1) | optional |

### Deliberately skipped
`riverpod`, `dio`, `go_router`, `firebase_crashlytics`, `tflite_flutter` — not needed for this scope.

---

## 5. Data flow

### 5.1 Wearable → Phone (BLE)

The wristband exposes one GATT service with three characteristics:

| Characteristic | Type | Payload | Direction |
|---|---|---|---|
| `readings` | Notify | Packed bytes: `hr (u8) · spo2 (u8) · temp (i16 / 100) · ax · ay · az (i16) · ts (u32)` | wearable → phone |
| `device_info` | Read | Battery %, firmware version | wearable → phone |
| `commands` | Write | 1 byte opcode: vibrate, set sample rate, calibrate | phone → wearable |

Phone subscribes to `readings` and receives a new sample every 1–5 s.

### 5.2 Phone → Local cache

Every incoming sample lands in:
- An in-memory `Rx<HealthSample>` (GetX) — drives the live UI.
- A rolling local store (`get_storage` or Hive) keeping the last 24 h for offline history.

### 5.3 Phone → Cloud (Firestore)

Batched, not per-sample (would burn the free tier in minutes):

- Every **60 s** the app uploads the most recent batch to `users/{uid}/readings/{hourId}` as a single document with an array of samples.
- ML insight outputs go to `users/{uid}/insights/{id}` as they're produced.
- Medication / hydration logs go to `users/{uid}/care/{id}` on user action.

Offline-first: if there's no network, batches queue in local storage and flush when the app reconnects.

### 5.4 Phone → Wearable

User actions that need feedback on the wrist (e.g. "vibrate when reminder fires", "set HR alarm threshold") map to a BLE write on the `commands` characteristic.

### 5.5 ML inference

- Random Forest is **trained offline** in Python (sklearn) on a public sickle-cell-relevant dataset (or synthetic data for the prototype).
- Trees + thresholds are exported as JSON, shipped in `assets/ml/model.json`.
- Dart `InferenceService` loads the JSON once at startup; on every new window of samples (e.g. 30 s), it produces one `InsightLabel`.
- Insights are persisted locally and synced to Firestore.

---

## 6. UI philosophy

**Simple. Modern. Functional. Calm.**

Translated to concrete rules for every screen:

- **Information first** — readings and statuses are the loudest things on every screen. Decoration recedes.
- **One primary action per screen** at most. No competing CTAs.
- **No cards-by-default** — use whitespace and rhythm before reaching for borders or shadows. When a card is right, it's a single, generous one — never nested.
- **No gradient text, no glassmorphism, no side-stripe borders.** (Per `/impeccable` shared design laws.)
- **Light theme only** for v1. Calmer for a clinical context, easier outdoors.
- **Type:** FormaDJR. Hierarchy through weight + size, not color.
- **Color:** neutrals tinted toward the brand hue. One restrained accent (green) for connected / OK states; a deeper red only for genuine alerts.
- **Motion:** subtle. `Curves.easeOutQuart` or `Curves.easeOutExpo`. No bounce, no elastic. Animate `opacity` and `transform` — never layout dimensions.
- **States:** every screen has loading, empty, error, and offline states designed from day one.
- **Copy:** plain English, no jargon, no em-dashes. "Connected" not "Bluetooth status: paired."

---

## 7. Module map

Bottom-nav app shell with five tabs.

### 7.1 Dashboard
Live vitals at a glance.
- Connection pill (top-right): Connected · Searching · Off.
- Live HR · SpO₂ · Temperature · Activity.
- Today's insight (one sentence, ML-generated).
- "Last updated" timestamp.

### 7.2 History
Look back at the data.
- Day / week / month toggle.
- Trend lines per metric.
- Tap a point → detail view (timestamp, raw values, what the model said).

### 7.3 Insights
The AI explainer.
- Today's status: Normal · Watch · Alert.
- Cards explaining *why* (e.g. "SpO₂ dipped below 92% twice in the last hour").
- Recommendations: hydrate, rest, contact your doctor.

### 7.4 Care
Hydration + medication.
- Today's water intake (progress ring or simple bar — pick after `/impeccable shape`).
- Quick-add buttons (+250 ml, +500 ml).
- Medication list with next-dose chip; tap to mark "taken" or "skipped."

### 7.5 Profile
- Account info + sign out.
- Wearable: connected device, battery, firmware version, "forget device."
- App settings: reminder times, alert thresholds, units.

---

## 8. Execution plan

Each phase ends with something runnable. Each can be paused or reordered.

| Phase | Goal | Why now | Status |
|---|---|---|---|
| **0. Foundation** | Project structure, fonts, theme, core packages, PRDs | Already complete | ✅ |
| **1. Navigation shell** | `HomeShell` with bottom nav + five empty themed screens | Unlocks visual iteration | ✅ |
| **2. Firebase setup** | Project `will-wristband` created, FlutterFire wired, Auth + Firestore enabled, login / signup screens | Backend ready before BLE | ✅ |
| **3. BLE integration** | `WearableService`, mock mode toggle, Dashboard live with real-or-fake data | Hardware-agnostic UI build | ✅ |
| **4. Local cache + sync** | Samples persisted locally, batched to Firestore, offline-first | History becomes real | ✅ |
| **5. ML inference** | Random Forest trained, exported, embedded, `InferenceService` produces labels | Insights tab becomes real | ✅ |
| **6. Reminders** | Local notifications for hydration + medication; FCM only if needed | Care tab becomes real | ✅ |
| **7. Polish** | Animated values, real Profile content, no-band banner, action feedback | After structure is locked | ✅ |
| **8. Harden** | Firestore security rules deployed, defensive reads, lazy notification perm, README, init failsafes | Pre-defence | ✅ |

---

## 9. Out of scope for v1

Listed so they don't sneak in mid-build:

- Doctor / caregiver dashboard (web)
- GPS emergency tracking
- Over-the-air firmware updates from the app
- Custom-PCB smartwatch form factor
- Cloud-side ML or LLM-style chat
- Crashlytics, analytics
- Multi-language support
- Tablet / desktop layouts
- Wear OS / watchOS companions

All belong in "Future improvements" of the academic PRD.

---

## 10. Open questions for you to answer

Before we kick off Phase 1:

1. **Account ownership** — confirm `wisdomiyamu@gmail.com` is fine to own the Firebase project long-term (not the school account).
2. **Mock data first?** Build the BLE service in "mock mode" so the app produces fake samples on a timer, letting us finish the UI before the hardware is ready. (Recommended.)
3. **Dataset for ML** — do you have a labeled dataset, or do we synthesize one for the prototype?
4. **Hydration goal** — fixed (e.g. 2.5 L/day) or user-configurable from the start?
5. **Onboarding** — email/password only, or add Google sign-in too?

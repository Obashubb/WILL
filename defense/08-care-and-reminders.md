# Care and reminders

## What it does

The Care tab is the practical, day-to-day part of the app. Two things live there:

1. **Hydration tracking** — log water intake during the day, see a progress ring against a daily goal, get a midday nudge if you forget.
2. **Medications** — keep a list of medications (name, dose, the times of day they should be taken), get a notification when each dose is due, mark each one as taken.

There is also a third notification path that doesn't live on the Care tab: **insight alerts**. When the on-device ML model flags something concerning (low oxygen, possible stress, dehydration pattern) with high enough confidence, the app vibrates the wristband and shows a system notification — even if the app is in the background.

## How it works

```
                              ┌──────────────────────────┐
   User taps "+250 ml"  ───►  │     CareController       │
                              │  (GetX reactive state)   │
                              └────────────┬─────────────┘
                                           │
                            ┌──────────────┴───────────────┐
                            ▼                              ▼
                  ┌──────────────────┐         ┌──────────────────────┐
                  │ CareRepository   │         │ NotificationService  │
                  │  get_storage     │         │ flutter_local_       │
                  │   care.hydration │         │   notifications      │
                  │   care.meds      │         │   meds / hydration / │
                  │   care.med_logs  │         │   alerts channels    │
                  └──────────────────┘         └──────────────────────┘
```

**Hydration.** Every time the user taps a quick-add button (`+250 ml`, `+500 ml`), an entry lands in `get_storage` under `care.hydration`. The Care screen recomputes today's total against the configured goal (`2500 ml` by default) and animates the progress ring. A small daily notification at 13:00 nudges anyone who hasn't logged water in a while.

**Medications.** A medication is `{ name, dose, times[], active }`. Saving one immediately schedules a `zonedSchedule` daily reminder for each time slot using `DateTimeComponents.time` so it recurs every day. Deleting a medication cancels its slots. Tapping a dose chip on a medication writes a `MedicationLog` with `status: taken`.

**Insight alerts.** When `InferenceService` publishes an Insight with `isConcerning == true` AND `confidence >= 0.7`, it does two things — once per label per 5-minute cooldown:

1. Writes `WearableCommand.vibrate` to the band's commands characteristic, so the wrist buzzes.
2. Calls `NotificationService.fireInsightAlert(...)` which surfaces a system notification on the `alerts` channel with `interruptionLevel: timeSensitive` on iOS.

Three notification channels are registered on Android (Medication reminders, Hydration reminders, Health alerts) so the user can mute them independently in system settings without losing the others.

## Why we built it this way

**Tradeoff 1 — local vs. FCM.** Push from a server (FCM) would let us alert a doctor or family member too. But it adds a server, certificates, billing, and offline failure modes. The PRD only requires reminders for the patient themselves, so on-device scheduling is enough — and it works without internet.

**Tradeoff 2 — daily recurring schedule vs. background-fetch logic.** A "smart" hydration reminder that only fires if intake is below threshold would need a background task. iOS makes that fragile. A simple one-shot daily nudge at a chosen time is dumb but works the same every time.

**Tradeoff 3 — debounce the insight alert.** Without a cooldown, a five-minute stretch of borderline stress readings would buzz the band every two seconds. A 5-minute cooldown per label means at most a handful of alerts per hour, which is what the PRD intends.

**Tradeoff 4 — separate channels.** Bundling everything into one channel is easier to implement, but then the user can't say "I want medication reminders but no hydration nudges." Three channels = three independent on/off switches in system settings.

## Why this fits our scope

- The PRD asks for hydration tracking, medication reminders, abnormal-condition alerts, and notifications. The Care tab and the alert path cover all four.
- No servers, no certificates, no recurring cost.
- The same data model used locally is ready to be mirrored to Firestore in a future phase if the project ever needs a caregiver dashboard.

## Example walkthrough

It's 08:00. Ada's phone buzzes with **"Hydroxyurea — Time for your 500 mg"**. She opens the Care tab, taps the **08:00** chip on the Hydroxyurea row, and it turns green with a check mark. A `MedicationLog` lands in storage. Later, around midday, the phone fires the **"Hydration check — Have a glass of water if you can."** notification. Ada drinks 500 ml of water and taps **+500 ml** in the app; the ring on the Care tab fills another notch. At 15:30 her band reports a low-SpO₂ pattern. `InferenceService` produces an Insight labelled **Low oxygen** with confidence 0.82, which:

1. Sends a vibrate command to her band — she feels it on her wrist.
2. Fires a high-priority notification on the alerts channel.
3. Updates the Insights tab with the new state and recommendations.

If she stays in the low-SpO₂ window for the next 60 seconds, no second alert fires because the cooldown is still active.

## Where to look

- `lib/models/hydration_entry.dart`, `lib/models/medication.dart` — data shapes (entries, medications, logs).
- `lib/services/care_repository.dart` — local persistence (hydration, medications, dose logs).
- `lib/services/notification_service.dart` — scheduling, cancellation, and immediate alert paths. Channel ids and id-generation logic live here.
- `lib/view/care/care_controller.dart` — GetX controller; recomputes totals, schedules and cancels reminders on add / delete.
- `lib/view/care/care_screen.dart` — hydration ring, quick-add buttons, medication list.
- `lib/view/care/add_medication_sheet.dart` — modal bottom sheet to add or edit a medication.
- `lib/services/inference_service.dart` → `_maybeAlert` — the bridge from ML output to vibrate + notification.
- `android/app/src/main/AndroidManifest.xml` — `POST_NOTIFICATIONS`, exact-alarm permissions.

## Further reading

- [flutter_local_notifications docs](https://pub.dev/packages/flutter_local_notifications) — scheduling, channels, exact alarms.
- [Android 13+ notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission) — why we ask at runtime.
- [iOS `interruptionLevel` (time-sensitive notifications)](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel) — when iOS lets us cut through Focus modes.

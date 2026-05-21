# Storage

## What it does

The app has to remember things. Some belong on the phone (recent readings, the user's settings). Others should be backed up online, so the data survives a phone reset or can be seen on a second device. This document covers both.

## How it works

WILL uses **three layers** of storage, each picked for a specific kind of data:

| Layer | Purpose | Package | Example |
|---|---|---|---|
| **Secure storage** | Things that must be encrypted at rest | `flutter_secure_storage` | The Firebase auth token |
| **Local key-value** | Small everyday values | `get_storage` | Hydration goal, last-known wearable id |
| **Cloud (Firestore)** | Long-term history, syncable across devices | `cloud_firestore` | Sensor readings, medication logs |

**The flow.** When the wearable sends a reading, it lands first in memory — the live UI updates instantly. Then we save the recent readings locally so history still works offline. Once a minute, we batch the new readings and push them to Firebase as a single document.

Think of it like a journal you keep with you (local) plus a copy you mail to a safety-deposit box once a day (cloud).

## Why we built it this way

**Tradeoff 1 — everything in the cloud vs. local first.** We could write every reading directly to Firebase. Simpler code. But:

- Each Firebase write counts against the free tier (about 20,000 writes per day).
- With no internet, the user would lose data.
- The UI would feel slow because every reading would round-trip through a server.

So we keep data locally first and batch-upload. The user gets instant feedback, and the cloud just receives summaries.

**Tradeoff 2 — three packages vs. one.** A single database (like SQLite or Hive) could hold everything. But:

- Secure-storage hardware (Android Keystore, iOS Keychain) is built for sensitive things — using it for tokens is just safer.
- `get_storage` is dead simple for small key-value pairs and pairs naturally with our state-management package (GetX).
- Firestore is the natural choice for the cloud layer.

Each tool is small and fits its job, so the cost of using all three is low.

**Tradeoff 3 — batching every minute.** Less often = less cost, but worse responsiveness if the user opens the app on a new device. Once a minute is a good balance for sensor data that does not need to be live across devices.

## Why this fits our scope

The PRD asks for:

- Real-time monitoring → handled by in-memory + local cache.
- Historical records → handled by local + cloud.
- Working offline → the wearable still streams to the phone with no internet; the phone keeps a local copy.
- Secure storage → the auth token is encrypted at rest.

This layered approach delivers each requirement with the simplest possible tool for the job.

## Example walkthrough

Imagine the wearable sends a new heart-rate reading of 78 bpm:

1. The Bluetooth service receives the bytes and parses them into a `HealthSample`.
2. The sample is published to a GetX reactive stream — the Dashboard tab redraws.
3. The sample is appended to a list in `get_storage` (`local.readings.today`).
4. A timer fires every 60 seconds. It picks up all readings since the last upload, packs them into one Firestore document, writes it under `users/{uid}/readings/{hourId}`, then clears the local "to-upload" queue.
5. If the user has no internet, step 4 fails silently. The queue grows. When internet returns, the next timer tick uploads the backlog.

## Current state

- `get_storage` holds `app.user`, `device.seenSetup`, `device.pairedId`, `samples.recent` (last 24 h of readings), and `samples.pending` (queue waiting to upload).
- `flutter_secure_storage` is wired in but not yet writing anything custom — the Firebase Auth SDK handles token storage internally.
- `SyncService` runs every 60 seconds, groups pending samples by hour, and writes them under `users/{uid}/readings/{hourId}` with `FieldValue.arrayUnion` so retries are safe.
- Guest users have no Firebase uid — `SyncService` notices and skips. Their data lives only on the phone.

## Where to look

- `pubspec.yaml` — confirms `get_storage`, `flutter_secure_storage`, `cloud_firestore`.
- `lib/services/profile_service.dart` — local user profile + onboarding flags.
- `lib/services/samples_repository.dart` — recent-history cache + upload queue.
- `lib/services/sync_service.dart` — the batched uploader.

## Further reading

- [Cloud Firestore basics](https://firebase.google.com/docs/firestore/quickstart)
- [get_storage on pub.dev](https://pub.dev/packages/get_storage)
- [flutter_secure_storage on pub.dev](https://pub.dev/packages/flutter_secure_storage)

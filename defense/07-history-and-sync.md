# History and sync

## What it does

Sensor readings stream in continuously from the wearable. This part of the system makes sure they:

1. Show up **immediately** on the dashboard.
2. Get **saved on the phone** so the History tab still works offline.
3. Get **backed up to the cloud** so the user (or a doctor, later) can review the data on any device.

## How it works

Every reading the `WearableService` produces is funnelled through a single method, `_publish()`, which fans the sample out to three places at once:

```
                  ┌─────────────────────────┐
                  │   WearableService       │
                  │   ._publish(sample)     │
                  └────────────┬────────────┘
                               │
       ┌───────────────────────┼───────────────────────┐
       ▼                       ▼                       ▼
┌───────────────┐      ┌──────────────────┐    ┌──────────────────┐
│ latestSample  │      │ samples.recent   │    │ samples.pending  │
│  (Rxn)        │      │  (24-hour cache) │    │  (upload queue)  │
│  drives the   │      │  drives History  │    │  drained every   │
│  dashboard    │      │  trend chart     │    │  60 s by Sync    │
└───────────────┘      └──────────────────┘    └──────────────────┘
                                                          │
                                                  ┌───────▼─────────┐
                                                  │   SyncService   │
                                                  │  Firestore      │
                                                  │  users/{uid}/   │
                                                  │   readings/     │
                                                  │   {hourId}      │
                                                  └─────────────────┘
```

**Cache layer (`SamplesRepository`)**, two lists in `get_storage`:

- `samples.recent`, appended on every sample; anything older than 24 hours is pruned automatically. The History tab reads from here.
- `samples.pending`, append-only queue. Samples are removed once Firestore confirms them.

**Sync layer (`SyncService`)**, a `Timer` that fires every 60 seconds:

1. Read the pending queue.
2. Group samples by hour (one Firestore document per hour per user).
3. For each group, `set` the document with `FieldValue.arrayUnion(samples)` and `merge: true`. Re-running with the same samples is a no-op, so retries are safe.
4. On success, remove those samples from the pending queue.
5. On any failure (no internet, permission denied, write conflict), samples stay queued. The next tick retries.

If there is no signed-in Firebase user (i.e. guest mode), `SyncService` returns silently. Guest data lives only on the phone.

## Why we built it this way

**Tradeoff 1, write each sample to Firestore vs. batch.** Direct writes are simpler but every sample costs a Firestore write. With one sample every 2 seconds across many users we would blow the free quota fast. Batching by hour drops the cost to one document update per hour, no matter how many samples land in that hour.

**Tradeoff 2, local cache vs. read from cloud every time.** Reading the full history from Firestore on every Dashboard open would be slow and burn read quota. Keeping 24 hours locally makes the History tab instant and works without internet. The cloud is the long-term archive, not the live source.

**Tradeoff 3, `arrayUnion` vs. nested writes.** `arrayUnion` deduplicates automatically. If the network drops mid-upload and the same batch tries again next tick, Firestore won't write the same sample twice. We don't need a complex acknowledgement protocol.

**Tradeoff 4, one document per hour vs. one per day.** A day's worth of samples (~43,000 if we sample at 0.5 Hz) is too big for a single Firestore document (the 1 MiB limit). Hour buckets keep each document well under that ceiling and make queries by time range simple.

## Why this fits our scope

- The PRD calls for real-time monitoring, offline operation, and cloud sync. This layered model delivers all three with very simple code.
- The single `_publish` funnel keeps the contract clean: any new transport (a different wearable, a manual import) only needs to call `_publish` and everything downstream just works.
- The chart on the History tab is powered entirely by local data, so the demo works in the defense room whether the Wi-Fi cooperates or not.

## Example walkthrough

Ada wears her band for an hour:

1. The band emits a sample every 2 seconds. Each one runs through `WearableService._publish()`.
2. The dashboard's connection pill stays green, the four metric cards (HR, SpO₂, temperature, activity) update on every emission.
3. After 60 seconds, `SyncService` fires. The pending queue has 30 samples, all in the same hour bucket, say `20260521-13`. It writes one document to `users/{uid}/readings/20260521-13` with the 30 samples in an array. The pending queue empties.
4. Ada switches to the History tab and taps the **Temperature** chip. The chart reads the 24-hour cache, picks out the temperature values, and draws a smooth line.
5. Ada loses Wi-Fi for an hour. The band keeps emitting; samples pile up in `samples.pending` (and still appear in History because `samples.recent` is separate). When connectivity returns, the next sync tick flushes the backlog in one or two batched writes.

## Where to look

- `lib/services/wearable_service.dart` → `_publish`, single fan-out point.
- `lib/services/samples_repository.dart`, both local lists.
- `lib/services/sync_service.dart`, the timer + Firestore writer.
- `lib/view/history/history_screen.dart`, chart, metric picker, headline values.
- `firestore.rules`, guarantees one user can only read their own subtree.

## Further reading

- [Firestore array operations (arrayUnion / arrayRemove)](https://firebase.google.com/docs/firestore/manage-data/add-data#update_elements_in_an_array)
- [Firestore document size limit (1 MiB)](https://firebase.google.com/docs/firestore/quotas#writes_and_transactions)
- [fl_chart on pub.dev](https://pub.dev/packages/fl_chart)

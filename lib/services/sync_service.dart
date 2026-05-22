import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/health_sample.dart';
import 'insights_repository.dart';
import 'samples_repository.dart';

/// Periodic batched uploader for sensor readings.
///
/// Behaviour:
///  * Runs every [interval] (default 60 s).
///  * Reads the pending queue from [SamplesRepository].
///  * Groups by hour and writes each group to
///    `users/{uid}/readings/{hourId}` using `arrayUnion` so re-runs are safe.
///  * Skips silently if there is no signed-in Firebase user (guest mode).
///  * On any error, samples stay in the queue and we retry on the next tick.
class SyncService extends GetxService {
  Timer? _timer;
  bool _flushing = false;

  final RxBool isOnline = true.obs;
  final RxnString lastError = RxnString();
  final Rxn<DateTime> lastSyncedAt = Rxn<DateTime>();

  static const Duration interval = Duration(seconds: 60);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => flushNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }

  Future<void> flushNow() async {
    if (_flushing) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // guest, nothing to sync.

    _flushing = true;
    try {
      await _flushReadings(uid);
      await _flushInsights(uid);
      lastSyncedAt.value = DateTime.now();
      lastError.value = null;
      isOnline.value = true;
    } catch (e) {
      lastError.value = e.toString();
      isOnline.value = false;
    } finally {
      _flushing = false;
    }
  }

  Future<void> _flushReadings(String uid) async {
    final pending = SamplesRepository.readPending();
    if (pending.isEmpty) return;
    try {
      final byHour = <String, List<HealthSample>>{};
      for (final s in pending) {
        byHour.putIfAbsent(_hourId(s.timestamp), () => []).add(s);
      }

      for (final entry in byHour.entries) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('readings')
            .doc(entry.key);
        await ref.set({
          'hour': entry.key,
          'updatedAt': FieldValue.serverTimestamp(),
          'samples': FieldValue.arrayUnion(
            entry.value.map((s) => s.toJson()).toList(),
          ),
        }, SetOptions(merge: true));
      }

      await SamplesRepository.removePending(pending);
    } catch (e) {
      // Bubble up, handled in flushNow.
      rethrow;
    }
  }

  Future<void> _flushInsights(String uid) async {
    final pending = InsightsRepository.readPending();
    if (pending.isEmpty) return;
    final uploaded = <dynamic>[];
    for (final insight in pending) {
      try {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('insights')
            .doc(insight.id);
        await ref.set({
          ...insight.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        uploaded.add(insight);
      } catch (e) {
        // Stop on first failure, keep the rest queued for the next tick.
        break;
      }
    }
    if (uploaded.isNotEmpty) {
      await InsightsRepository.removePending(uploaded.cast());
    }
  }

  /// Bucket id = `YYYYMMDD-HH`. One Firestore document per hour per user.
  static String _hourId(DateTime ts) {
    final local = ts.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    return '$y$m$d-$h';
  }
}

import 'package:get_storage/get_storage.dart';

import '../models/insight.dart';

/// Local persistence of insights + per-insight user feedback. Mirrors
/// [SamplesRepository] so the patterns stay consistent.
///
/// Three lists in `get_storage`:
///  * `insights.recent`  , last 50 events shown on the Insights timeline,
///                          7-day retain.
///  * `insights.pending` , upload queue drained by [SyncService].
///  * `insights.feedback`, per-insight ✓ / ✗ taps. Local only for now;
///                          used as a future training signal.
class InsightsRepository {
  InsightsRepository._();

  static final GetStorage _box = GetStorage();

  static const String _recentKey = 'insights.recent';
  static const String _pendingKey = 'insights.pending';
  static const String _feedbackKey = 'insights.feedback';

  static const Duration _retain = Duration(days: 7);
  static const int _maxRecent = 200;

  // -- Recent (timeline) -------------------------------------------------

  static List<Insight> readRecent() =>
      _safeReadList(_recentKey, Insight.fromJson);

  static Future<void> appendRecent(Insight insight) async {
    final list = readRecent()..add(insight);
    final cutoff = DateTime.now().subtract(_retain);
    list.removeWhere((i) => i.timestamp.isBefore(cutoff));
    if (list.length > _maxRecent) {
      list.removeRange(0, list.length - _maxRecent);
    }
    await _box.write(_recentKey, list.map((i) => i.toJson()).toList());
  }

  static Future<void> clearRecent() => _box.remove(_recentKey);

  // -- Pending (upload queue) --------------------------------------------

  static List<Insight> readPending() =>
      _safeReadList(_pendingKey, Insight.fromJson);

  static Future<void> enqueuePending(Insight insight) async {
    final list = readPending()..add(insight);
    await _box.write(_pendingKey, list.map((i) => i.toJson()).toList());
  }

  static Future<void> removePending(Iterable<Insight> uploaded) async {
    final ids = uploaded.map((i) => i.id).toSet();
    final list = readPending()..removeWhere((i) => ids.contains(i.id));
    await _box.write(_pendingKey, list.map((i) => i.toJson()).toList());
  }

  // -- Feedback ----------------------------------------------------------

  static List<InsightFeedback> readFeedback() =>
      _safeReadList(_feedbackKey, InsightFeedback.fromJson);

  static Future<void> appendFeedback(InsightFeedback feedback) async {
    final list = readFeedback()..add(feedback);
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    list.removeWhere((f) => f.actedAt.isBefore(cutoff));
    await _box.write(_feedbackKey, list.map((f) => f.toJson()).toList());
  }

  /// True if the user has already given feedback on this insight.
  static bool hasFeedback(String insightId) =>
      readFeedback().any((f) => f.insightId == insightId);

  // -- Misc --------------------------------------------------------------

  static Future<void> clearAll() async {
    await _box.remove(_recentKey);
    await _box.remove(_pendingKey);
    await _box.remove(_feedbackKey);
  }

  static List<T> _safeReadList<T>(
    String key,
    T Function(Map<String, dynamic>) decoder,
  ) {
    final out = <T>[];
    final raw = _box.read<List>(key);
    if (raw == null) return out;
    for (final e in raw) {
      try {
        out.add(decoder(Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    return out;
  }
}

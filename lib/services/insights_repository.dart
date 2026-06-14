import 'package:get_storage/get_storage.dart';

import '../models/health_sample.dart';
import '../models/insight.dart';
import 'inference_service.dart';

/// Local persistence for past insights. The Insights History screen reads
/// `readRecent()`; live classifications hit `recordIfMeaningful()` which
/// applies a transition-aware rate limit so long calm stretches don't
/// dump 30 calm entries per minute.
class InsightsRepository {
  InsightsRepository._();

  static final GetStorage _box = GetStorage();

  static const String _key = 'insights.recent';
  static const int _maxRecent = 200;
  static const Duration _retain = Duration(days: 7);
  static const Duration _heartbeat = Duration(minutes: 5);

  /// Persists [result] for [sample] if it represents a meaningful change
  /// since the last persisted entry, OR if 5+ minutes have passed since
  /// the last heartbeat.
  ///
  /// Returns the persisted Insight, or `null` when we chose to skip.
  static Insight? recordIfMeaningful(
    InsightResult result,
    HealthSample sample,
  ) {
    final list = readRecent();
    final last = list.isEmpty ? null : list.first;
    final now = sample.timestamp;
    if (last != null) {
      final sameLabel = last.severity == result.severity &&
          last.condition == result.condition;
      final freshEnough = now.difference(last.timestamp) < _heartbeat;
      if (sameLabel && freshEnough) return null;
    }
    final insight = Insight(
      id: Insight.buildId(now, result.severity, result.condition),
      timestamp: now,
      severity: result.severity,
      condition: result.condition,
      sample: sample,
    );
    final updated = <Insight>[insight, ...list];
    _writeAll(_pruneAndCap(updated));
    return insight;
  }

  /// Returns the saved insights, newest first. Stale entries (older than
  /// the retain window) are pruned on read so the list stays meaningful.
  static List<Insight> readRecent() {
    final raw = _box.read<List<dynamic>>(_key);
    if (raw == null) return <Insight>[];
    final all = <Insight>[];
    for (final entry in raw) {
      try {
        all.add(Insight.fromJson(Map<String, dynamic>.from(entry as Map)));
      } catch (_) {
        // Skip anything that no longer parses (schema drift).
      }
    }
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _pruneAndCap(all);
  }

  /// Updates the helpful flag on a saved insight (if it still exists).
  /// Used by the live tab's feedback row and the detail screen.
  static Future<void> rate(String id, bool helpful) async {
    final all = readRecent();
    final updated = all
        .map((i) => i.id == id ? i.copyWith(helpful: helpful) : i)
        .toList();
    await _writeAll(updated);
  }

  static Future<void> clearAll() => _box.remove(_key);

  static List<Insight> _pruneAndCap(List<Insight> all) {
    final cutoff = DateTime.now().subtract(_retain);
    final kept = all.where((i) => i.timestamp.isAfter(cutoff)).toList();
    if (kept.length > _maxRecent) {
      return kept.sublist(0, _maxRecent);
    }
    return kept;
  }

  static Future<void> _writeAll(List<Insight> all) =>
      _box.write(_key, all.map((i) => i.toJson()).toList());
}

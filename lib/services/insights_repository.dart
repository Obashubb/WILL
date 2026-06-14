import 'package:get_storage/get_storage.dart';

import '../models/health_sample.dart';
import '../models/insight.dart';
import 'inference_service.dart';

class InsightsRepository {
  InsightsRepository._();

  static final GetStorage _box = GetStorage();

  static const String _key = 'insights.recent';
  static const int _maxRecent = 200;
  static const Duration _retain = Duration(days: 7);
  static const Duration _heartbeat = Duration(minutes: 5);

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

  static List<Insight> readRecent() {
    final raw = _box.read<List<dynamic>>(_key);
    if (raw == null) return <Insight>[];
    final all = <Insight>[];
    for (final entry in raw) {
      try {
        all.add(Insight.fromJson(Map<String, dynamic>.from(entry as Map)));
      } catch (_) {}
    }
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _pruneAndCap(all);
  }

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

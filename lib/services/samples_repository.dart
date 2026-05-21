import 'package:get_storage/get_storage.dart';

import '../models/health_sample.dart';

/// Persists health samples locally so History works offline and the
/// uploader has something to flush to Firestore.
///
/// Two stores, both in `get_storage`:
///  * `samples.recent`  — rolling 24-hour view used by the History screen.
///  * `samples.pending` — queue of samples not yet acknowledged by Firestore.
class SamplesRepository {
  SamplesRepository._();

  static final GetStorage _box = GetStorage();

  static const String _recentKey = 'samples.recent';
  static const String _pendingKey = 'samples.pending';

  static const Duration _retain = Duration(hours: 24);

  // -- Recent (history) --------------------------------------------------

  static List<HealthSample> readRecent() {
    final raw = _box.read<List>(_recentKey);
    if (raw == null) return const [];
    return raw
        .map((e) => HealthSample.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> appendRecent(HealthSample sample) async {
    final list = readRecent()..add(sample);
    final cutoff = DateTime.now().subtract(_retain);
    list.removeWhere((s) => s.timestamp.isBefore(cutoff));
    await _box.write(_recentKey, list.map((s) => s.toJson()).toList());
  }

  static Future<void> clearRecent() => _box.remove(_recentKey);

  // -- Pending (upload queue) --------------------------------------------

  static List<HealthSample> readPending() {
    final raw = _box.read<List>(_pendingKey);
    if (raw == null) return const [];
    return raw
        .map((e) => HealthSample.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> enqueuePending(HealthSample sample) async {
    final list = readPending()..add(sample);
    await _box.write(_pendingKey, list.map((s) => s.toJson()).toList());
  }

  static Future<void> removePending(Iterable<HealthSample> uploaded) async {
    final uploadedTimestamps = uploaded.map((s) => s.timestamp).toSet();
    final list = readPending()
      ..removeWhere((s) => uploadedTimestamps.contains(s.timestamp));
    await _box.write(_pendingKey, list.map((s) => s.toJson()).toList());
  }

  static Future<void> clearPending() => _box.remove(_pendingKey);

  static Future<void> clearAll() async {
    await _box.remove(_recentKey);
    await _box.remove(_pendingKey);
  }
}

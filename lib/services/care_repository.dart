import 'package:get_storage/get_storage.dart';

import '../models/hydration_entry.dart';
import '../models/medication.dart';

/// Persists hydration intake, medication definitions, and medication logs
/// to local storage. All reads are synchronous and cheap (small data).
class CareRepository {
  CareRepository._();

  static final GetStorage _box = GetStorage();

  static const String _hydrationKey = 'care.hydration';
  static const String _medsKey = 'care.medications';
  static const String _logsKey = 'care.med_logs';
  static const String _hydrationGoalKey = 'care.hydration_goal_ml';

  static const int defaultHydrationGoalMl = 2500;

  // -- Hydration ---------------------------------------------------------

  static int hydrationGoalMl() =>
      _box.read<int>(_hydrationGoalKey) ?? defaultHydrationGoalMl;

  static Future<void> setHydrationGoalMl(int ml) =>
      _box.write(_hydrationGoalKey, ml);

  static List<HydrationEntry> readHydrationToday() {
    final start = _startOfToday();
    return _readHydrationAll().where((e) => !e.timestamp.isBefore(start)).toList();
  }

  static int hydrationTodayMl() =>
      readHydrationToday().fold(0, (sum, e) => sum + e.amountMl);

  static Future<void> addHydration(int amountMl) async {
    final entry = HydrationEntry(
      id: 'h_${DateTime.now().microsecondsSinceEpoch}',
      amountMl: amountMl,
      timestamp: DateTime.now(),
    );
    final all = _readHydrationAll()..add(entry);
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    all.removeWhere((e) => e.timestamp.isBefore(cutoff));
    await _box.write(
      _hydrationKey,
      all.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> removeHydration(String id) async {
    final all = _readHydrationAll()..removeWhere((e) => e.id == id);
    await _box.write(
      _hydrationKey,
      all.map((e) => e.toJson()).toList(),
    );
  }

  static List<HydrationEntry> _readHydrationAll() =>
      _safeReadList(_hydrationKey, (m) => HydrationEntry.fromJson(m));

  // -- Medications -------------------------------------------------------

  static List<Medication> readMedications() =>
      _safeReadList(_medsKey, (m) => Medication.fromJson(m));

  static Future<void> saveMedication(Medication med) async {
    final list = readMedications();
    final i = list.indexWhere((m) => m.id == med.id);
    if (i == -1) {
      list.add(med);
    } else {
      list[i] = med;
    }
    await _box.write(_medsKey, list.map((m) => m.toJson()).toList());
  }

  static Future<void> deleteMedication(String id) async {
    final list = readMedications()..removeWhere((m) => m.id == id);
    await _box.write(_medsKey, list.map((m) => m.toJson()).toList());
  }

  // -- Medication logs ---------------------------------------------------

  static List<MedicationLog> readLogs() =>
      _safeReadList(_logsKey, (m) => MedicationLog.fromJson(m));

  static Future<void> appendLog(MedicationLog log) async {
    final list = readLogs()..add(log);
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    list.removeWhere((l) => l.actedAt.isBefore(cutoff));
    await _box.write(_logsKey, list.map((l) => l.toJson()).toList());
  }

  // -- Misc --------------------------------------------------------------

  static Future<void> clearAll() async {
    await _box.remove(_hydrationKey);
    await _box.remove(_medsKey);
    await _box.remove(_logsKey);
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
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

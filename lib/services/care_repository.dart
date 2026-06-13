import 'package:get_storage/get_storage.dart';

import '../models/hydration_entry.dart';
import '../models/medications.dart';

class CareRepository {
  CareRepository._();

  static final GetStorage _box = GetStorage();
  static const String _hydrationKey = 'care.hydration';
  static const String _goalKey = 'care.goal';
  static const String _medicationsKey = 'care.medications';
  static const int defaultGoalMl = 3000;

  /// Reads the user's daily water goal, or the default if none is set.
  static int readGoal() {
    return _box.read<int>(_goalKey) ?? defaultGoalMl;
  }

  static Future<void> setGoal(int goal) async {
    await _box.write(_goalKey, goal);
  }

  /// Reads every hydration entry ever saved.
  static List<HydrationEntry> _readAll() {
    final raw = _box.read<List<dynamic>>(_hydrationKey);
    if (raw == null) return [];
    return raw.map((e) => HydrationEntry.fromJson(e)).toList();
  }

  /// Reads only the entries logged today.
  static List<HydrationEntry> readToday() {
    final now = DateTime.now();
    return _readAll().where((e) {
      return e.timestamp.year == now.year &&
          e.timestamp.month == now.month &&
          e.timestamp.day == now.day;
    }).toList();
  }

  /// Adds up all of today's water into a single total (in millilitres).
  static int todayTotalMl() {
    return readToday().fold(0, (a, b) => a + b.amountMl);
  }

  static Future<void> addHydrationEntry(int amountMl) async {
    final list = _readAll();
    list.add(HydrationEntry(amountMl: amountMl, timestamp: DateTime.now()));
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    list.removeWhere((e) => e.timestamp.isBefore(cutoff));
    await _box.write(_hydrationKey, list.map((e) => e.toJson()).toList());
  }

  ///Medications

  /// Reads the patient's full medication list.
  static List<Medications> readMedications() {
    final raw = _box.read<List<dynamic>>(_medicationsKey);
    if (raw == null) return [];
    return raw
        .map((e) => Medications.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Saves the whole medication list (used after add, update, or delete).
  static Future<void> _writeMedications(List<Medications> meds) async {
    await _box.write(_medicationsKey, meds.map((m) => m.toJson()).toList());
  }

  /// Adds a new medication to the list.
  static Future<void> addMedication(Medications med) async {
    final meds = readMedications()..add(med);
    await _writeMedications(meds);
  }

  /// Replaces an existing medication (matched by id) with an updated version.
  /// Used when marking a med as taken.
  static Future<void> updateMedication(Medications updated) async {
    final meds = readMedications();
    final index = meds.indexWhere((m) => m.id == updated.id);
    if (index == -1) return;
    meds[index] = updated;
    await _writeMedications(meds);
  }

  /// Removes a medication by its id.
  static Future<void> deleteMedication(String id) async {
    final meds = readMedications();
    meds.removeWhere((m) => m.id == id);
    await _writeMedications(meds);
  }
}

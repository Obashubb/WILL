import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/hydration_entry.dart';
import '../../models/medication.dart';
import '../../services/care_repository.dart';
import '../../services/notification_service.dart';

class CareController extends GetxController {
  final RxList<HydrationEntry> hydrationToday = <HydrationEntry>[].obs;
  final RxList<Medication> medications = <Medication>[].obs;
  final RxList<MedicationLog> todayLogs = <MedicationLog>[].obs;
  final RxInt hydrationGoalMl = CareRepository.defaultHydrationGoalMl.obs;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  void refreshAll() {
    hydrationToday.assignAll(CareRepository.readHydrationToday());
    medications.assignAll(CareRepository.readMedications());
    final today = DateTime.now();
    todayLogs.assignAll(
      CareRepository.readLogs().where(
        (l) =>
            l.actedAt.year == today.year &&
            l.actedAt.month == today.month &&
            l.actedAt.day == today.day,
      ),
    );
    hydrationGoalMl.value = CareRepository.hydrationGoalMl();
  }

  int get hydrationTotalMl =>
      hydrationToday.fold(0, (sum, e) => sum + e.amountMl);

  double get hydrationProgress {
    final goal = hydrationGoalMl.value;
    if (goal <= 0) return 0;
    return (hydrationTotalMl / goal).clamp(0.0, 1.0);
  }

  Future<void> addHydration(int amountMl) async {
    await CareRepository.addHydration(amountMl);
    refreshAll();
  }

  Future<void> removeHydration(String id) async {
    await CareRepository.removeHydration(id);
    refreshAll();
  }

  Future<void> setHydrationGoal(int ml) async {
    await CareRepository.setHydrationGoalMl(ml);
    hydrationGoalMl.value = ml;
  }

  Future<void> saveMedication(Medication med) async {
    await CareRepository.saveMedication(med);
    // Make sure we have notification permission before scheduling. If the
    // user denies it, the medication still saves — they just won't see a
    // reminder until they grant it later.
    await NotificationService.requestPermission();
    await NotificationService.scheduleMedicationReminders(med);
    refreshAll();
  }

  Future<void> deleteMedication(String id) async {
    await NotificationService.cancelMedicationReminders(id);
    await CareRepository.deleteMedication(id);
    refreshAll();
  }

  Future<void> logDose({
    required Medication med,
    required TimeOfDay scheduledTime,
    required MedicationLogStatus status,
  }) async {
    final now = DateTime.now();
    final scheduledFor = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    await CareRepository.appendLog(MedicationLog(
      medicationId: med.id,
      scheduledFor: scheduledFor,
      actedAt: now,
      status: status,
    ));
    refreshAll();
  }

  bool doseLoggedFor(Medication med, TimeOfDay slot) {
    return todayLogs.any((l) {
      if (l.medicationId != med.id) return false;
      return l.scheduledFor.hour == slot.hour &&
          l.scheduledFor.minute == slot.minute;
    });
  }

  /// Next dose across all medications that hasn't been logged today yet.
  ({Medication med, TimeOfDay slot})? get nextDose {
    final now = TimeOfDay.now();
    final minutesNow = now.hour * 60 + now.minute;
    ({Medication med, TimeOfDay slot, int delta})? best;
    for (final m in medications.where((m) => m.active)) {
      for (final t in m.times) {
        if (doseLoggedFor(m, t)) continue;
        final minutes = t.hour * 60 + t.minute;
        final delta = minutes - minutesNow;
        if (delta >= -15) {
          // Allow a 15-minute grace window after a slot.
          if (best == null || delta < best.delta) {
            best = (med: m, slot: t, delta: delta);
          }
        }
      }
    }
    return best == null ? null : (med: best.med, slot: best.slot);
  }
}

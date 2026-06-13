import 'package:get/get.dart';

import '../../models/medications.dart';
import '../../services/care_repository.dart';
import '../../services/notification_service.dart';

class CareController extends GetxController {
  /// Today's total water intake in millilitres.
  final RxInt todayWaterMl = 0.obs;

  /// The user's daily water goal in millilitres.
  final RxInt goalMl = CareRepository.defaultGoalMl.obs;

  /// The patient's medication list.
  final RxList<Medications> medications = <Medications>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadEverything();
    _setupReminders();
  }

  Future<void> _setupReminders() async {
    final notifications = Get.find<NotificationService>();
    await notifications.requestPermissions();
    await notifications.scheduleHydrationReminders();
  }

  /// Pulls the latest saved values into the reactive variables.
  void _loadEverything() {
    todayWaterMl.value = CareRepository.todayTotalMl();
    goalMl.value = CareRepository.readGoal();
    medications.value = CareRepository.readMedications();
  }

  /// Logs water and refreshes today's total.
  Future<void> addWater(int amountMl) async {
    await CareRepository.addHydrationEntry(amountMl);
    todayWaterMl.value = CareRepository.todayTotalMl();
  }

  /// Updates the daily goal (user-configurable).
  Future<void> updateGoal(int newGoalMl) async {
    await CareRepository.setGoal(newGoalMl);
    goalMl.value = newGoalMl;
  }

  /// Progress as a value between 0.0 and 1.0, for the progress ring/bar.
  double get progress {
    if (goalMl.value == 0) return 0;
    return (todayWaterMl.value / goalMl.value).clamp(0.0, 1.0);
  }

  /// Adds a new medication, saves it, and schedules its daily reminder.
  Future<void> addMedication(Medications med) async {
    await CareRepository.addMedication(med);
    await Get.find<NotificationService>().scheduleMedication(med);
    medications.value = CareRepository.readMedications();
  }

  /// Marks a medication as taken today (stamps lastTakenDate with now).
  Future<void> markTaken(Medications med) async {
    final updated = med.copyWith(lastTakenDate: DateTime.now());
    await CareRepository.updateMedication(updated);
    medications.value = CareRepository.readMedications();
  }

  /// Deletes a medication and cancels its reminder.
  Future<void> deleteMedication(Medications med) async {
    await CareRepository.deleteMedication(med.id);
    await Get.find<NotificationService>().cancelMedication(med);
    medications.value = CareRepository.readMedications();
  }
}

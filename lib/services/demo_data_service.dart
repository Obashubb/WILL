import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/health_sample.dart';
import '../models/hydration_entry.dart';
import '../models/medication.dart';
import 'care_repository.dart';
import 'notification_service.dart';
import 'samples_repository.dart';
import 'wearable_service.dart';

/// One-stop test harness. Lets you seed plausible medications, hydration
/// intake, and a few hours of historical sensor data in a tap — and switch
/// the live mock generator between scenarios so the Insights tab can be
/// driven through every label without real hardware.
class DemoDataService {
  DemoDataService._();

  static final Random _rng = Random();

  // -- Scenarios ---------------------------------------------------------

  static void setScenario(MockScenario scenario) {
    Get.find<WearableService>().mockScenario.value = scenario;
  }

  // -- Sample medications ------------------------------------------------

  static Future<void> seedMedications() async {
    final samples = <Medication>[
      Medication(
        id: 'demo_hydroxyurea',
        name: 'Hydroxyurea',
        dose: '500 mg',
        times: const [
          TimeOfDay(hour: 8, minute: 0),
          TimeOfDay(hour: 20, minute: 0),
        ],
      ),
      Medication(
        id: 'demo_folic',
        name: 'Folic acid',
        dose: '1 mg',
        times: const [TimeOfDay(hour: 9, minute: 0)],
      ),
      Medication(
        id: 'demo_paludrine',
        name: 'Paludrine',
        dose: '100 mg',
        times: const [TimeOfDay(hour: 13, minute: 0)],
      ),
    ];
    for (final m in samples) {
      await CareRepository.saveMedication(m);
      await NotificationService.scheduleMedicationReminders(m);
    }
  }

  // -- Today's hydration -------------------------------------------------

  static Future<void> seedHydrationDay() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 7);
    // Five plausible entries spread between 07:00 and now.
    final entries = <HydrationEntry>[];
    final pours = [250, 500, 250, 350, 500];
    for (var i = 0; i < pours.length; i++) {
      final t = start.add(Duration(hours: i * 2, minutes: _rng.nextInt(30)));
      if (t.isAfter(now)) break;
      entries.add(HydrationEntry(
        id: 'demo_h_$i',
        amountMl: pours[i],
        timestamp: t,
      ));
    }
    for (final e in entries) {
      await CareRepository.addHydration(e.amountMl);
    }
  }

  // -- History samples ---------------------------------------------------

  /// Generates [hours] of mostly-normal data with a short stretch of each
  /// abnormal pattern so every metric on the History chart has texture.
  static Future<void> seedHistory({int hours = 6}) async {
    final now = DateTime.now();
    final samples = <HealthSample>[];
    final stepSeconds = 30; // one sample every 30 s of synthetic time.
    final totalSteps = hours * 3600 ~/ stepSeconds;

    // Define abnormal windows as fractions of the total span.
    bool inWindow(int step, double from, double to) {
      final f = step / totalSteps;
      return f >= from && f <= to;
    }

    for (var step = 0; step < totalSteps; step++) {
      final ts = now.subtract(
        Duration(seconds: (totalSteps - step) * stepSeconds),
      );
      MockScenario scenario = MockScenario.normal;
      if (inWindow(step, 0.20, 0.25)) {
        scenario = MockScenario.stress;
      } else if (inWindow(step, 0.50, 0.55)) {
        scenario = MockScenario.dehydration;
      } else if (inWindow(step, 0.78, 0.82)) {
        scenario = MockScenario.abnormalOxygen;
      }
      samples.add(_syntheticSample(ts, scenario));
    }
    await SamplesRepository.replaceRecent(samples);
  }

  static HealthSample _syntheticSample(DateTime ts, MockScenario scenario) {
    int hr;
    int spo2;
    double temp;
    double motion;
    switch (scenario) {
      case MockScenario.normal:
        hr = 72 + _rng.nextInt(9) - 4;
        spo2 = 96 + _rng.nextInt(3);
        temp = 36.6 + _rng.nextDouble() * 0.3;
        motion = _rng.nextDouble() * 0.3;
      case MockScenario.stress:
        hr = 108 + _rng.nextInt(9) - 4;
        spo2 = 95 + _rng.nextInt(3);
        temp = 36.8 + _rng.nextDouble() * 0.2;
        motion = _rng.nextDouble() * 0.05;
      case MockScenario.dehydration:
        hr = 94 + _rng.nextInt(7) - 3;
        spo2 = 95 + _rng.nextInt(3);
        temp = 37.4 + _rng.nextDouble() * 0.3;
        motion = _rng.nextDouble() * 0.05;
      case MockScenario.abnormalOxygen:
        hr = 95 + _rng.nextInt(9) - 4;
        spo2 = 88 + _rng.nextInt(4);
        temp = 36.8 + _rng.nextDouble() * 0.2;
        motion = _rng.nextDouble() * 0.2;
      case MockScenario.crisis:
        hr = 120 + _rng.nextInt(9) - 4;
        spo2 = 86 + _rng.nextInt(4);
        temp = 38.0 + _rng.nextDouble() * 0.4;
        motion = _rng.nextDouble() * 0.05;
    }
    return HealthSample(
      heartRate: hr,
      spo2: spo2,
      temperature: double.parse(temp.toStringAsFixed(1)),
      motion: double.parse(motion.toStringAsFixed(2)),
      timestamp: ts,
    );
  }

  // -- Reset -------------------------------------------------------------

  /// Wipes care + samples, cancels all pending notifications, and resets
  /// the scenario to normal. The signed-in user is untouched.
  static Future<void> resetAll() async {
    await CareRepository.clearAll();
    await SamplesRepository.clearAll();
    await NotificationService.cancelAll();
    Get.find<WearableService>().mockScenario.value = MockScenario.normal;
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/medications.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<NotificationService> init() async {
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: androidInit, iOS: iOSInit);
    await _plugin.initialize(settings);

    return this;
  }

  Future<void> requestPermissions() async {
    // iOS permission request
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ permission request
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Schedules a daily repeating reminder for one medication.
  Future<void> scheduleMedication(Medications med) async {
    await _plugin.zonedSchedule(
      med.id.hashCode, // unique notification id derived from the med's id
      'Time for your medication',
      '${med.name} — ${med.dose}',
      _nextInstanceOf(med.hour, med.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meds_channel',
          'Medication reminders',
          channelDescription: 'Daily reminders to take medication',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  /// Cancels a medication's reminder (e.g. when the med is deleted).
  Future<void> cancelMedication(Medications med) async {
    await _plugin.cancel(med.id.hashCode);
  }

  /// Schedules hydration reminders at a few fixed times during the day.
  Future<void> scheduleHydrationReminders() async {
    // Remind at 10am, 2pm, and 6pm. Ids 1001-1003 are reserved for these.
    final times = [(10, 0), (14, 0), (18, 0)];
    for (var i = 0; i < times.length; i++) {
      await _plugin.zonedSchedule(
        1001 + i,
        'Time to hydrate',
        'Have some water to stay on top of your goal.',
        _nextInstanceOf(times[i].$1, times[i].$2),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel',
            'Hydration reminders',
            channelDescription: 'Reminders to drink water',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showAlert(String title, String body) async {
    await _plugin.show(
      7777,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alert_channel',
          'Health alerts',
          channelDescription: 'Critical health alerts from your readings',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Works out the next time a given hour:minute will occur.
  /// If 8:00 has already passed today, it returns 8:00 tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

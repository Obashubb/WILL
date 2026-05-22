import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';

/// Wraps flutter_local_notifications with the channels and IDs we use.
///
/// Channels:
///  * `meds`      — medication reminders, scheduled daily.
///  * `hydration` — daily hydration nudge.
///  * `alerts`    — fired immediately when the ML model flags a concerning
///                  pattern (low oxygen, possible stress, etc.).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _medsChannel = 'will.meds';
  static const String _hydrationChannel = 'will.hydration';
  static const String _alertsChannel = 'will.alerts';

  static const int _hydrationId = 999999;
  static const int _alertIdBase = 800000;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final ok =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      return ok ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final ok = await android.requestNotificationsPermission();
      return ok ?? true;
    }
    return true;
  }

  // -- Medications -------------------------------------------------------

  static Future<void> scheduleMedicationReminders(Medication med) async {
    await cancelMedicationReminders(med.id);
    if (!med.active) return;
    for (var i = 0; i < med.times.length; i++) {
      final time = med.times[i];
      await _plugin.zonedSchedule(
        id: _medicationNotificationId(med.id, i),
        title: med.name,
        body: 'Time for your ${med.dose}',
        scheduledDate: _nextInstanceOf(time.hour, time.minute),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _medsChannel,
            'Medication reminders',
            channelDescription: 'Daily reminders to take your medication.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelMedicationReminders(String medId) async {
    // Cancel up to 10 slots per medication (we never schedule more than that).
    for (var i = 0; i < 10; i++) {
      await _plugin.cancel(id: _medicationNotificationId(medId, i));
    }
  }

  // -- Hydration ---------------------------------------------------------

  static Future<void> scheduleDailyHydrationNudge({
    int hour = 13,
    int minute = 0,
  }) async {
    await _plugin.cancel(id: _hydrationId);
    await _plugin.zonedSchedule(
      id: _hydrationId,
      title: 'Hydration check',
      body: 'Have a glass of water if you can.',
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _hydrationChannel,
          'Hydration reminders',
          channelDescription: 'Daily nudge to keep you hydrated.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelHydrationNudge() =>
      _plugin.cancel(id: _hydrationId);

  // -- Alerts ------------------------------------------------------------

  static Future<void> fireInsightAlert({
    required String title,
    required String body,
    int tag = 0,
  }) async {
    await _plugin.show(
      id: _alertIdBase + tag,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _alertsChannel,
          'Health alerts',
          channelDescription:
              'Fires when the on-device model flags an abnormal reading.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  // -- Helpers -----------------------------------------------------------

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
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

  static int _medicationNotificationId(String medId, int slot) {
    // Stable hash → keeps cancel/reschedule deterministic. Must fit in a
    // 32-bit signed int (≈ 2.14 billion); we keep well under that ceiling
    // by capping the hash at 100 M before multiplying by 10 for the slot.
    final hash = medId.hashCode.abs() % 100000000;
    return hash * 10 + slot;
  }
}

extension TimeOfDayFormat on TimeOfDay {
  String formatHm() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

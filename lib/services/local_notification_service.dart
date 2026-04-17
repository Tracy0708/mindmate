import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // Notification IDs for each type
  static const int dailyMoodId = 1;
  static const int breathingId = 2;
  static const int weeklySummaryId = 3;
  static const int motivationalId = 4;

  /// Initialize the notification plugin — call once at app startup
  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print('Could not get local timezone: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Request notification permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule a daily notification at the given hour:minute
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindmate_reminders',
          'MindMate Reminders',
          channelDescription: 'Daily mental health reminders from MindMate',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a weekly notification (e.g. every Sunday)
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(DateTime.sunday, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindmate_weekly',
          'MindMate Weekly',
          channelDescription: 'Weekly progress summaries from MindMate',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Send an immediate test notification
  Future<void> showTestNotification() async {
    await _plugin.show(
      99,
      '🧠 MindMate',
      'Notifications are working! You will receive your reminders.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindmate_reminders',
          'MindMate Reminders',
          channelDescription: 'Daily mental health reminders from MindMate',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Apply notification preferences from the settings screen
  Future<void> applyPreferences({
    required bool masterEnabled,
    required bool dailyMood,
    required bool breathing,
    required bool weeklySummary,
    required bool motivational,
    required int hour,
    required int minute,
  }) async {
    // Cancel all first, then re-schedule only the enabled ones
    await cancelAll();

    if (!masterEnabled) return;

    if (dailyMood) {
      await scheduleDailyNotification(
        id: dailyMoodId,
        title: '😊 How are you feeling?',
        body: 'Take a moment to log your mood today.',
        hour: hour,
        minute: minute,
      );
    }

    if (breathing) {
      await scheduleDailyNotification(
        id: breathingId,
        title: '🌿 Time to breathe',
        body: 'A short breathing exercise can help reduce stress.',
        hour: hour,
        minute: minute + 30 >= 60 ? (minute + 30) - 60 : minute + 30,
      );
    }

    if (weeklySummary) {
      await scheduleWeeklyNotification(
        id: weeklySummaryId,
        title: '📊 Your Weekly Summary',
        body: 'Check out your mood trends from this week!',
        hour: 10,
        minute: 0,
      );
    }

    if (motivational) {
      await scheduleDailyNotification(
        id: motivationalId,
        title: '💛 Daily Inspiration',
        body: _getMotivationalQuote(),
        hour: 8,
        minute: 0,
      );
    }
  }

  // ─── Private Helpers ───

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _getMotivationalQuote() {
    final quotes = [
      'You are stronger than you think. Keep going! 💪',
      'Every day is a fresh start. Make it count! ☀️',
      'Be kind to yourself — you deserve it. 🌸',
      'Small steps still move you forward. 🚶‍♀️',
      'Your mental health matters. Take care of you. 💛',
    ];
    return quotes[DateTime.now().day % quotes.length];
  }
}

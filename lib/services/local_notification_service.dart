import 'dart:developer' as developer;
import 'dart:ui';
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
  static const String pushChannelId = 'mindmate_push';
  static const String pushChannelName = 'MindMate Notifications';
  static const int dailyMoodId = 1;
  static const int breathingId = 2;
  static const int weeklySummaryId = 3;
  static const int motivationalId = 4;
  
  // Admin Notification IDs
  static const int adminHighRiskId = 10;
  static const int adminNewSignupId = 11;
  static const int adminSystemReportId = 12;
  static const int adminAbnormalBehaviorId = 13;

  /// Initialize the notification plugin — call once at app startup
  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      developer.log('Could not get local timezone: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Request notification permissions on Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        pushChannelId,
        pushChannelName,
        description: 'MindMate app notifications',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'mindmate_reminders',
        'MindMate Reminders',
        description: 'Daily mental health reminders from MindMate',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'mindmate_weekly',
        'MindMate Weekly',
        description: 'Weekly progress summaries from MindMate',
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'mindmate_admin_alerts',
        'MindMate Admin Alerts',
        description: 'Critical alerts for MindMate administrators',
        importance: Importance.max,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();

    // Request exact alarm permission so reminders fire on time.
    // On Android 12+ this opens the "Alarms & Reminders" settings page if
    // the permission has not been granted yet.
    final canExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
    if (!canExact) {
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  Future<bool> _canUseExactAlarms() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  /// Schedule a daily notification at the given hour:minute
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final scheduleMode = await _canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

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
      androidScheduleMode: scheduleMode,
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
    final scheduleMode = await _canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

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
      androidScheduleMode: scheduleMode,
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
      '🧠 MindMate Admin',
      'Alerts are working! You will receive your notifications.',
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

  /// Show an immediate app push while the app is in the foreground.
  Future<void> showPushNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          pushChannelId,
          pushChannelName,
          channelDescription: 'MindMate app notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Show an immediate admin real-time alert
  Future<void> showAdminRealtimeAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindmate_admin_alerts',
          'MindMate Admin Alerts',
          channelDescription: 'Critical alerts for MindMate administrators',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFFB300),
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
        hour: (minute + 30 >= 60) ? (hour + 1) % 24 : hour,
        minute: (minute + 30) % 60,
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

  /// Apply admin notification preferences
  Future<void> applyAdminPreferences({
    required bool masterEnabled,
    required bool highRiskAlerts,
    required bool newSignups,
    required bool systemReports,
    required bool abnormalBehavior,
    required int hour,
    required int minute,
  }) async {
    // Cancel all first
    await cancelAll();

    if (!masterEnabled) return;

    if (systemReports) {
      await scheduleDailyNotification(
        id: adminSystemReportId,
        title: '📈 Daily System Report',
        body: 'Your daily overview of platform usage and signals is ready.',
        hour: hour,
        minute: minute,
      );
    }
    
    // Other admin alerts (High Risk, New Signups, Abnormal Behavior) 
    // are typically triggered dynamically by Cloud Functions or Firestore listeners.
    // For demonstration of local notification settings, we simulate their setup here.
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

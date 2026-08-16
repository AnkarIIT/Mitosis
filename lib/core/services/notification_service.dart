import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _remindersEnabledKey = 'study_reminders_enabled';
  static const String _reminderTimeKey = 'study_reminder_time';

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    debugPrint('🔔 Notification Service Initialized');
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    return result ?? false;
  }

  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await _notificationsPlugin.cancel(0); // Cancel existing reminder

    await _notificationsPlugin.zonedSchedule(
      0,
      'Time to Study! 📚',
      'Keep your streak alive. Practice 10 Biology questions now.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminders',
          'Study Reminders',
          channelDescription: 'Daily reminders to practice for NEET',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Save settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, true);
    await prefs.setString(_reminderTimeKey, '$hour:$minute');
    
    debugPrint('⏰ Daily reminder scheduled for $hour:$minute');
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, false);
    debugPrint('🔕 All reminders cancelled');
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersEnabledKey) ?? false;
  }

  Future<String> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_reminderTimeKey) ?? '20:00';
  }
}

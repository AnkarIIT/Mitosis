import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _remindersEnabledKey = 'study_reminders_enabled';
  static const String _reminderTimeKey = 'study_reminder_time';

  Future<void> init() async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
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

  /// Resolves the device timezone. Without this, the daily nudge would be
  /// scheduled against UTC and fire at the wrong wall-clock time.
  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) return;

    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      if (timeZoneName.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Timezone lookup failed: $e');
    }

    _setLocalTimeZoneFromOffset();
  }

  /// Best-effort fallback using the current device UTC offset (whole hours).
  void _setLocalTimeZoneFromOffset() {
    final totalMinutes = DateTime.now().timeZoneOffset.inMinutes;
    if (totalMinutes == 0) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      return;
    }
    final sign = totalMinutes > 0 ? '-' : '+'; // Etc/GMT signs are inverted.
    final hours = totalMinutes.abs() ~/ 60;
    tz.setLocalLocation(tz.getLocation('Etc/GMT$sign$hours'));
  }

  Future<bool> _canScheduleExactAlarms() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.canScheduleExactNotifications() ??
        false;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    return result ?? false;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return; // Scheduled local notifications are Android/iOS only.

    await _notificationsPlugin.cancel(0); // Cancel existing reminder

    final canExact = await _canScheduleExactAlarms();
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
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Save settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, true);
    await prefs.setString(_reminderTimeKey, '$hour:$minute');

    debugPrint(
      '⏰ Daily reminder scheduled for $hour:$minute (exact=$canExact)',
    );
  }

  /// Re-asserts the stored reminder after app launches. This heals schedules
  /// that were lost (e.g. previous broken builds, alarms dropped on reboot
  /// before the boot receiver existed).
  Future<void> ensureDailyReminderScheduled() async {
    if (kIsWeb) return;
    if (!await areRemindersEnabled()) return;

    final time = await getReminderTime();
    final parts = time.split(':');
    if (parts.length != 2) return;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    try {
      await scheduleDailyReminder(hour: hour, minute: minute);
      debugPrint('✅ Daily study nudge re-asserted for $time');
    } catch (e) {
      debugPrint('❌ Failed to re-assert daily nudge: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, false);
    debugPrint('🔕 All reminders cancelled');
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
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

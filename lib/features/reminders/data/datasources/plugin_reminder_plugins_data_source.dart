import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:memox/features/reminders/data/datasources/reminder_plugins_data_source.dart';

/// [ReminderPluginsDataSource] on the real plugins: the one file that imports
/// them (guard `memox_v8.architecture.reminder_plugins_have_one_door`). It
/// holds no logic the adapter's tests would miss: each method is one plugin
/// call, set up as the plugins' READMEs give it.
final class PluginReminderPluginsDataSource
    implements ReminderPluginsDataSource {
  /// [onAlarm] is the `@pragma('vm:entry-point')` callback the alarm runs in
  /// the background (`reminder_background_bindings.dart`).
  PluginReminderPluginsDataSource(this._onAlarm);

  final Future<void> Function() _onAlarm;
  final _notifications = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String?>.broadcast();
  Future<void>? _ready;

  static const _channel = AndroidNotificationDetails(
    'daily_reminder',
    'Daily reminder',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  /// A failed start is not remembered: the next call tries again.
  @override
  Future<void> initialize() =>
      _ready ??= _initialize().catchError((Object error) {
        _ready = null;
        throw error;
      });

  Future<void> _initialize() async {
    await AndroidAlarmManager.initialize();
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _taps.add(response.payload),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool?> requestNotificationPermission() async {
    await initialize();
    return _android?.requestNotificationsPermission();
  }

  @override
  Future<bool> scheduleAlarm(DateTime at) async {
    await initialize();
    await AndroidAlarmManager.cancel(reminderAlarmId);
    return AndroidAlarmManager.oneShotAt(
      at,
      reminderAlarmId,
      _onAlarm,
      allowWhileIdle: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  @override
  Future<bool> cancelAlarm() async {
    await initialize();
    return AndroidAlarmManager.cancel(reminderAlarmId);
  }

  @override
  Future<void> showNotification(String body) async {
    await initialize();
    await _notifications.show(
      id: reminderNotificationId,
      body: body,
      notificationDetails: const NotificationDetails(android: _channel),
      payload: reminderTapPayload,
    );
  }

  @override
  Future<void> cancelNotification() async {
    await initialize();
    await _notifications.cancel(id: reminderNotificationId);
  }

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    await initialize();
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }
}

/// The id of the one pending reminder alarm: scheduling again replaces it
/// (BR-REMINDER-009, BR-REMINDER-010).
const int reminderAlarmId = 7001;

/// The id of the day's one notification: a new day's replaces the last
/// (BR-REMINDER-004).
const int reminderNotificationId = 7001;

/// What a tap on the reminder carries: it opens Study Home (BR-REMINDER-008).
const String reminderTapPayload = 'study-home';

/// The two reminder plugins behind one door (BE-B5b):
/// `plugin_reminder_plugins_data_source.dart` is the only file that imports
/// them, and the adapter's tests fake this interface, since the plugins do
/// nothing on the host. Calls may throw; the adapter maps every throw to the
/// port's typed reason.
abstract interface class ReminderPluginsDataSource {
  /// Readies both plugins in this isolate. Idempotent.
  Future<void> initialize();

  /// The notification permission: `true` granted, `false` refused, `null`
  /// where the platform has no such permission (Android before 13).
  Future<bool?> requestNotificationPermission();

  /// One inexact alarm at [at] under [reminderAlarmId], replacing any pending
  /// one. `false` when the platform refused it.
  Future<bool> scheduleAlarm(DateTime at);

  /// Removes the pending alarm. `false` when the platform refused.
  Future<bool> cancelAlarm();

  /// Shows [body] under [reminderNotificationId], with [reminderTapPayload].
  Future<void> showNotification(String body);

  /// Removes the notification shown, if any.
  Future<void> cancelNotification();

  /// The payload of each tap on the notification while the app runs.
  Stream<String?> get taps;

  /// The payload of the tap that launched the app, or null.
  Future<String?> launchPayload();
}

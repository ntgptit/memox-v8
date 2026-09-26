import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

/// The next time the reminder fires: today at [minuteOfDay] while that is
/// still ahead and nothing was delivered today, tomorrow at [minuteOfDay]
/// otherwise (BR-REMINDER-002, BR-REMINDER-004).
///
/// Built from calendar fields in local time, never by adding 24 hours: the
/// offset of the day it lands on is the one used, so a clock change or a new
/// time zone keeps it on the chosen wall-clock time (reminders spec D11).
DateTime nextReminderAt({
  required DateTime now,
  required int minuteOfDay,
  DateTime? lastDeliveredAt,
}) {
  final local = now.toLocal();
  final hour = minuteOfDay ~/ Duration.minutesPerHour;
  final minute = minuteOfDay % Duration.minutesPerHour;
  final today = DateTime(local.year, local.month, local.day, hour, minute);
  if (today.isAfter(local) && !_deliveredOn(local, lastDeliveredAt)) {
    return today;
  }
  return DateTime(local.year, local.month, local.day + 1, hour, minute);
}

/// What a fire of the reminder is (reminders spec D12).
enum ReminderFireCheck {
  /// The reminder is off: the fire is left over from before.
  disabled,

  /// The local time has not reached the chosen minute: the alarm was
  /// deferred past midnight, or the person moved west.
  beforeReminderTime,

  /// The local day already had its digest (BR-REMINDER-004).
  alreadyDeliveredToday,

  /// The day's reminder.
  due,
}

ReminderFireCheck reminderFireCheckOf({
  required ReminderSettings reminder,
  required DateTime now,
  DateTime? lastDeliveredAt,
}) {
  if (!reminder.isEnabled) return ReminderFireCheck.disabled;
  final local = now.toLocal();
  final minuteNow = local.hour * Duration.minutesPerHour + local.minute;
  if (minuteNow < reminder.minuteOfDay) {
    return ReminderFireCheck.beforeReminderTime;
  }
  if (_deliveredOn(local, lastDeliveredAt)) {
    return ReminderFireCheck.alreadyDeliveredToday;
  }
  return ReminderFireCheck.due;
}

/// Whether [deliveredAt] falls on the local date of [day].
bool _deliveredOn(DateTime day, DateTime? deliveredAt) {
  if (deliveredAt == null) return false;
  final delivered = deliveredAt.toLocal();
  return delivered.year == day.year &&
      delivered.month == day.month &&
      delivered.day == day.day;
}

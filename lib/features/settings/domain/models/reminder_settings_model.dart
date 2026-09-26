import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';

/// The daily reminder a person set (UC-REMINDER-001): whether it is on, and
/// its time as a minute of the local day. This is the one definition of its
/// bounds and defaults; `app_settings` stores both values.
final class ReminderSettings {
  const ReminderSettings({required this.isEnabled, required this.minuteOfDay});

  /// BR-REMINDER-002: 00:00 to 23:59 of the local day.
  static const minMinuteOfDay = 0;
  static const maxMinuteOfDay = 1439;

  /// 20:00, the suggested time (BR-REMINDER-002).
  static const defaultMinuteOfDay = 1200;

  /// Off until the person turns it on (BR-REMINDER-001).
  static const defaults = ReminderSettings(
    isEnabled: false,
    minuteOfDay: defaultMinuteOfDay,
  );

  final bool isEnabled;

  /// Minutes after local midnight, read in the offset of the moment it is
  /// used and never converted to UTC (BR-REMINDER-002).
  final int minuteOfDay;

  Outcome<void, SettingsRejection> check() {
    if (minuteOfDay < minMinuteOfDay || minuteOfDay > maxMinuteOfDay) {
      return const Rejected(SettingsRejection.reminderMinuteOutOfRange);
    }
    return const Ok(null);
  }
}

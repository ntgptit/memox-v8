import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

/// What the reminder screen shows (UC-REMINDER-001 step 1): whether the
/// platform has reminders, and the reminder as stored. An unsupported
/// platform shows no toggle, even over a reminder stored as on
/// (BR-REMINDER-012).
final class ReminderStatus {
  const ReminderStatus({required this.capability, required this.reminder});

  final ReminderCapability capability;
  final ReminderSettings reminder;
}

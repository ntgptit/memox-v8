import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 A2: the person turns the reminder off. It is saved off
/// first, keeping its time, then the pending reminder is cancelled
/// (reminders spec D13). No permission is asked.
///
/// `couldNotCancel` comes back with the settings already off: a reminder may
/// still fire once, and skips itself when it reads them (E6). Calling this
/// again is the retry: it writes nothing and cancels. A save that fails
/// leaves as its `Failure` with nothing cancelled (E4).
final class DisableReminderUseCase {
  const DisableReminderUseCase(this._settings, this._platform);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;

  Future<Outcome<void, ReminderRejection>> call() async {
    final stored = (await _settings.reminderSnapshot()).reminder;
    if (stored.isEnabled) {
      // The stored minute is in range (its CHECK), so this is never refused.
      await _settings.saveReminder(
        reminder: ReminderSettings(
          isEnabled: false,
          minuteOfDay: stored.minuteOfDay,
        ),
      );
    }
    if (await _platform.capability() == ReminderCapability.unsupported) {
      return const Ok(null);
    }
    return _platform.cancel();
  }
}

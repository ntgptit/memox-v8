import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 A1: the person picks a new time. While the reminder is
/// on, the new time is scheduled before it is saved (reminders spec D13): a
/// refusal keeps the old time and its schedule (`couldNotSchedule`), and a
/// save that fails puts the old time back on the platform, as far as it
/// can, then leaves as its `Failure` (E4). While it is off, or the platform
/// has no reminders, only the time is saved and `Ok(null)` comes back
/// (spec D17). No permission is asked.
final class ChangeReminderTimeUseCase {
  const ChangeReminderTimeUseCase(this._settings, this._platform, this._clock);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;
  final DayClock _clock;

  Future<Outcome<DateTime?, ReminderRejection>> call({
    required int minuteOfDay,
  }) async {
    final wanted = ReminderSettings(isEnabled: true, minuteOfDay: minuteOfDay);
    if (wanted.check() case Rejected()) {
      return const Rejected(ReminderRejection.minuteOutOfRange);
    }
    final snapshot = await _settings.reminderSnapshot();
    final old = snapshot.reminder;
    final changed = ReminderSettings(
      isEnabled: old.isEnabled,
      minuteOfDay: minuteOfDay,
    );
    if (!old.isEnabled ||
        await _platform.capability() == ReminderCapability.unsupported) {
      // The minute was checked above, so this save is never refused.
      await _settings.saveReminder(reminder: changed);
      return const Ok(null);
    }
    final now = _clock.now();
    final nextAt = nextReminderAt(
      now: now,
      minuteOfDay: minuteOfDay,
      lastDeliveredAt: snapshot.lastDeliveredAt,
    );
    if (await _platform.schedule(at: nextAt) case Rejected(:final reason)) {
      return Rejected(reason);
    }
    try {
      await _settings.saveReminder(reminder: changed);
    } on Failure {
      await _platform.schedule(
        at: nextReminderAt(
          now: now,
          minuteOfDay: old.minuteOfDay,
          lastDeliveredAt: snapshot.lastDeliveredAt,
        ),
      );
      rethrow;
    }
    return Ok(nextAt);
  }
}

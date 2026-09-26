import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 A5: the pending reminder brought in line with the stored
/// one, at app start, after a reset and after a platform event such as a new
/// time zone (BR-REMINDER-009). Running it again changes nothing, as a
/// schedule replaces the pending reminder (BR-REMINDER-010), and it never
/// asks for the permission (BR-REMINDER-011).
///
/// `Ok(nextAt)` when it scheduled; `Ok(null)` when the reminder is off and
/// whatever was pending is cancelled, or when the platform has no reminders.
/// A settings read that fails leaves as its `Failure`.
final class ReconcileReminderUseCase {
  const ReconcileReminderUseCase(this._settings, this._platform, this._clock);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;
  final DayClock _clock;

  Future<Outcome<DateTime?, ReminderRejection>> call() async {
    if (await _platform.capability() == ReminderCapability.unsupported) {
      return const Ok(null);
    }
    final snapshot = await _settings.reminderSnapshot();
    if (!snapshot.reminder.isEnabled) {
      return switch (await _platform.cancel()) {
        Ok() => const Ok(null),
        Rejected(:final reason) => Rejected(reason),
      };
    }
    final nextAt = nextReminderAt(
      now: _clock.now(),
      minuteOfDay: snapshot.reminder.minuteOfDay,
      lastDeliveredAt: snapshot.lastDeliveredAt,
    );
    return switch (await _platform.schedule(at: nextAt)) {
      Ok() => Ok(nextAt),
      Rejected(:final reason) => Rejected(reason),
    };
  }
}

import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 steps 2-3: the person turns the reminder on at
/// [minuteOfDay]. Only now is the permission asked (BR-REMINDER-011), and
/// the reminder is scheduled before it is saved, so that "on" is never
/// stored without a pending reminder (reminders spec D13, D14).
///
/// `Ok(nextAt)`. `minuteOutOfRange`, `unsupported`, `permissionDenied` and
/// `couldNotSchedule` leave everything as it was (E1-E3). A save that fails
/// takes the schedule back, then leaves as its `Failure` (E4).
final class EnableReminderUseCase {
  const EnableReminderUseCase(this._settings, this._platform, this._clock);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;
  final DayClock _clock;

  Future<Outcome<DateTime, ReminderRejection>> call({
    required int minuteOfDay,
  }) async {
    final reminder = ReminderSettings(
      isEnabled: true,
      minuteOfDay: minuteOfDay,
    );
    if (reminder.check() case Rejected()) {
      return const Rejected(ReminderRejection.minuteOutOfRange);
    }
    if (await _platform.capability() == ReminderCapability.unsupported) {
      return const Rejected(ReminderRejection.unsupported);
    }
    if (await _platform.requestPermission() == ReminderPermission.denied) {
      return const Rejected(ReminderRejection.permissionDenied);
    }
    final snapshot = await _settings.reminderSnapshot();
    final nextAt = nextReminderAt(
      now: _clock.now(),
      minuteOfDay: minuteOfDay,
      lastDeliveredAt: snapshot.lastDeliveredAt,
    );
    if (await _platform.schedule(at: nextAt) case Rejected(:final reason)) {
      return Rejected(reason);
    }
    return switch (await _saveOrCancel(reminder)) {
      Ok() => Ok(nextAt),
      Rejected() => const Rejected(ReminderRejection.minuteOutOfRange),
    };
  }

  /// Saves [reminder]. A save that is refused or fails takes the schedule
  /// back first, so nothing is left pending for a reminder that stays off.
  /// The only refusal of `saveReminder` is the minute's range.
  Future<Outcome<void, SettingsRejection>> _saveOrCancel(
    ReminderSettings reminder,
  ) async {
    try {
      final saved = await _settings.saveReminder(reminder: reminder);
      if (saved case Rejected()) await _platform.cancel();
      return saved;
    } on Failure {
      await _platform.cancel();
      rethrow;
    }
  }
}

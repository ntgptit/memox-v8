import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

// The daily reminder's two values: off until a person turns it on, at a
// minute of the local day (BR-REMINDER-001, BR-REMINDER-002).

void main() {
  test('the reminder is off at 20:00 by default, in the app defaults too '
      '(BR-REMINDER-001, BR-REMINDER-002)', () {
    expect(ReminderSettings.defaults.isEnabled, isFalse);
    expect(ReminderSettings.defaults.minuteOfDay, 1200);
    expect(AppSettingsEntity.defaults.reminder.isEnabled, isFalse);
    expect(AppSettingsEntity.defaults.reminder.minuteOfDay, 1200);
  });

  for (final minute in [0, 1439]) {
    test('minute $minute of the local day is a reminder time '
        '(BR-REMINDER-002)', () {
      final result = ReminderSettings(
        isEnabled: true,
        minuteOfDay: minute,
      ).check();

      expect(result, isA<Ok<void, SettingsRejection>>());
    });
  }

  for (final minute in [-1, 1440]) {
    test('minute $minute is refused with its reason (BR-REMINDER-002)', () {
      final result = ReminderSettings(
        isEnabled: true,
        minuteOfDay: minute,
      ).check();

      expect(
        result,
        isA<Rejected<void, SettingsRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          SettingsRejection.reminderMinuteOutOfRange,
        ),
      );
    });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

// When the reminder fires next, and whether a fire is the day's reminder: a
// minute of the local day, read in the offset of the moment it is used
// (BR-REMINDER-002, BR-REMINDER-004; reminders spec D11, D12).

const _on2000 = ReminderSettings(isEnabled: true, minuteOfDay: 1200);

void main() {
  group('nextReminderAt', () {
    test("a time still ahead today is today's reminder "
        '(UC-REMINDER-001 step 3)', () {
      expect(
        nextReminderAt(now: DateTime(2026, 9, 26, 19), minuteOfDay: 1200),
        DateTime(2026, 9, 26, 20),
      );
    });

    test("a time already passed today is tomorrow's "
        '(UC-REMINDER-001 step 3)', () {
      expect(
        nextReminderAt(now: DateTime(2026, 9, 26, 21), minuteOfDay: 1200),
        DateTime(2026, 9, 27, 20),
      );
    });

    test('the very minute is not ahead: the next one is tomorrow', () {
      expect(
        nextReminderAt(now: DateTime(2026, 9, 26, 20), minuteOfDay: 1200),
        DateTime(2026, 9, 27, 20),
      );
    });

    test('a day that already had its digest moves to tomorrow, even with its '
        'new time still ahead (BR-REMINDER-004)', () {
      expect(
        nextReminderAt(
          now: DateTime(2026, 9, 26, 21),
          minuteOfDay: 1320,
          lastDeliveredAt: DateTime(2026, 9, 26, 20, 1),
        ),
        DateTime(2026, 9, 27, 22),
      );
    });

    test("yesterday's digest leaves today's reminder where it is "
        '(BR-REMINDER-004)', () {
      expect(
        nextReminderAt(
          now: DateTime(2026, 9, 26, 19),
          minuteOfDay: 1200,
          lastDeliveredAt: DateTime(2026, 9, 25, 20, 1),
        ),
        DateTime(2026, 9, 26, 20),
      );
    });

    test('month and year ends roll over to the first of the next', () {
      expect(
        nextReminderAt(now: DateTime(2026, 12, 31, 23), minuteOfDay: 1200),
        DateTime(2027, 1, 1, 20),
      );
      expect(
        nextReminderAt(now: DateTime(2026, 2, 28, 23), minuteOfDay: 1200),
        DateTime(2026, 3, 1, 20),
      );
    });

    test("minute 0 and minute 1439 are the day's first and last minute "
        '(BR-REMINDER-002)', () {
      final noon = DateTime(2026, 9, 26, 12);

      expect(nextReminderAt(now: noon, minuteOfDay: 0), DateTime(2026, 9, 27));
      expect(
        nextReminderAt(now: noon, minuteOfDay: 1439),
        DateTime(2026, 9, 26, 23, 59),
      );
    });

    test('the time is built from calendar fields, never 24 hours added: '
        'across a clock change it stays 20:00 (BR-REMINDER-002, spec D11)', () {
      // Europe moves its clocks on 29 March and 25 October 2026; 24 hours
      // after 20:00 lands on 21:00 or 19:00 there. Run with
      // TZ=Europe/Berlin to see it.
      final spring = nextReminderAt(
        now: DateTime(2026, 3, 28, 21),
        minuteOfDay: 1200,
      );
      final autumn = nextReminderAt(
        now: DateTime(2026, 10, 24, 21),
        minuteOfDay: 1200,
      );

      expect(spring, DateTime(2026, 3, 29, 20));
      expect(spring.hour, 20);
      expect(autumn, DateTime(2026, 10, 25, 20));
      expect(autumn.hour, 20);
    });
  });

  group('reminderFireCheckOf', () {
    test('a reminder that is off never fires (UC-REMINDER-001 E6)', () {
      expect(
        reminderFireCheckOf(
          reminder: const ReminderSettings(isEnabled: false, minuteOfDay: 1200),
          now: DateTime(2026, 9, 26, 20),
        ),
        ReminderFireCheck.disabled,
      );
    });

    test("at the chosen minute the fire is the day's reminder "
        '(UC-REMINDER-001 step 4)', () {
      expect(
        reminderFireCheckOf(reminder: _on2000, now: DateTime(2026, 9, 26, 20)),
        ReminderFireCheck.due,
      );
    });

    test('a fire late on the same day is still that day\'s reminder '
        '(spec D12)', () {
      expect(
        reminderFireCheckOf(
          reminder: _on2000,
          now: DateTime(2026, 9, 26, 23, 10),
        ),
        ReminderFireCheck.due,
      );
    });

    test('a minute early, the fire is not the reminder yet (spec D12)', () {
      expect(
        reminderFireCheckOf(
          reminder: _on2000,
          now: DateTime(2026, 9, 26, 19, 59),
        ),
        ReminderFireCheck.beforeReminderTime,
      );
    });

    test("a fire deferred past midnight is not yesterday's reminder, and not "
        "today's either (spec D12)", () {
      expect(
        reminderFireCheckOf(
          reminder: _on2000,
          now: DateTime(2026, 9, 27, 0, 30),
          lastDeliveredAt: DateTime(2026, 9, 25, 20, 1),
        ),
        ReminderFireCheck.beforeReminderTime,
      );
    });

    test('a day that already had its digest gets no second one '
        '(BR-REMINDER-004)', () {
      expect(
        reminderFireCheckOf(
          reminder: _on2000,
          now: DateTime(2026, 9, 26, 22),
          lastDeliveredAt: DateTime(2026, 9, 26, 20, 1),
        ),
        ReminderFireCheck.alreadyDeliveredToday,
      );
    });

    test('a delivery read back in UTC is compared on the local date '
        '(ADR-008)', () {
      // Just after local midnight, the UTC date east of Greenwich is still
      // the day before. Run with TZ=Europe/Berlin to see it.
      final delivered = DateTime(2026, 9, 26, 0, 30).toUtc();

      expect(
        reminderFireCheckOf(
          reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 0),
          now: DateTime(2026, 9, 26, 22),
          lastDeliveredAt: delivered,
        ),
        ReminderFireCheck.alreadyDeliveredToday,
      );
    });
  });
}

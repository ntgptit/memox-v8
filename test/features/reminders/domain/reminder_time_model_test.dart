import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

// When the reminder fires next, and whether a fire is the day's reminder: a
// minute of the local day, read in the offset of the moment it is used
// (BR-REMINDER-002, BR-REMINDER-004; reminders spec D11, D12).

const _on2000 = ReminderSettings(isEnabled: true, minuteOfDay: 1200);

void main() {
  group('nextReminderAt', () {
    // (now, minute of the day, last digest) -> the next fire.
    final cases = [
      (
        name:
            "a time still ahead today is today's reminder "
            '(UC-REMINDER-001 step 3)',
        now: DateTime(2026, 9, 26, 19),
        minuteOfDay: 1200,
        lastDeliveredAt: null,
        next: DateTime(2026, 9, 26, 20),
      ),
      (
        name:
            "a time already passed today is tomorrow's "
            '(UC-REMINDER-001 step 3)',
        now: DateTime(2026, 9, 26, 21),
        minuteOfDay: 1200,
        lastDeliveredAt: null,
        next: DateTime(2026, 9, 27, 20),
      ),
      (
        name: 'the very minute is not ahead: the next one is tomorrow',
        now: DateTime(2026, 9, 26, 20),
        minuteOfDay: 1200,
        lastDeliveredAt: null,
        next: DateTime(2026, 9, 27, 20),
      ),
      (
        name:
            'a day that already had its digest moves to tomorrow, even with '
            'its new time still ahead (BR-REMINDER-004)',
        now: DateTime(2026, 9, 26, 21),
        minuteOfDay: 1320,
        lastDeliveredAt: DateTime(2026, 9, 26, 20, 1),
        next: DateTime(2026, 9, 27, 22),
      ),
      (
        name:
            "yesterday's digest leaves today's reminder where it is "
            '(BR-REMINDER-004)',
        now: DateTime(2026, 9, 26, 19),
        minuteOfDay: 1200,
        lastDeliveredAt: DateTime(2026, 9, 25, 20, 1),
        next: DateTime(2026, 9, 26, 20),
      ),
      (
        name: 'a year end rolls over to the first of the next',
        now: DateTime(2026, 12, 31, 23),
        minuteOfDay: 1200,
        lastDeliveredAt: null,
        next: DateTime(2027, 1, 1, 20),
      ),
      (
        name: 'a month end rolls over to the first of the next',
        now: DateTime(2026, 2, 28, 23),
        minuteOfDay: 1200,
        lastDeliveredAt: null,
        next: DateTime(2026, 3, 1, 20),
      ),
      (
        name: "minute 0 is the day's first minute (BR-REMINDER-002)",
        now: DateTime(2026, 9, 26, 12),
        minuteOfDay: 0,
        lastDeliveredAt: null,
        next: DateTime(2026, 9, 27),
      ),
      (
        name: "minute 1439 is the day's last minute (BR-REMINDER-002)",
        now: DateTime(2026, 9, 26, 12),
        minuteOfDay: 1439,
        lastDeliveredAt: null,
        next: DateTime(2026, 9, 26, 23, 59),
      ),
    ];
    for (final c in cases) {
      test(c.name, () {
        expect(
          nextReminderAt(
            now: c.now,
            minuteOfDay: c.minuteOfDay,
            lastDeliveredAt: c.lastDeliveredAt,
          ),
          c.next,
        );
      });
    }

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
    // A delivery read back in UTC: just after local midnight, the UTC date
    // east of Greenwich is still the day before. Run with TZ=Europe/Berlin to
    // see it.
    final deliveredInUtc = DateTime(2026, 9, 26, 0, 30).toUtc();

    final cases = [
      (
        name: 'a reminder that is off never fires (UC-REMINDER-001 E6)',
        reminder: const ReminderSettings(isEnabled: false, minuteOfDay: 1200),
        now: DateTime(2026, 9, 26, 20),
        lastDeliveredAt: null,
        check: ReminderFireCheck.disabled,
      ),
      (
        name:
            "at the chosen minute the fire is the day's reminder "
            '(UC-REMINDER-001 step 4)',
        reminder: _on2000,
        now: DateTime(2026, 9, 26, 20),
        lastDeliveredAt: null,
        check: ReminderFireCheck.due,
      ),
      (
        name:
            "a fire late on the same day is still that day's reminder "
            '(spec D12)',
        reminder: _on2000,
        now: DateTime(2026, 9, 26, 23, 10),
        lastDeliveredAt: null,
        check: ReminderFireCheck.due,
      ),
      (
        name: 'a minute early, the fire is not the reminder yet (spec D12)',
        reminder: _on2000,
        now: DateTime(2026, 9, 26, 19, 59),
        lastDeliveredAt: null,
        check: ReminderFireCheck.beforeReminderTime,
      ),
      (
        name:
            "a fire deferred past midnight is not yesterday's reminder, and "
            "not today's either (spec D12)",
        reminder: _on2000,
        now: DateTime(2026, 9, 27, 0, 30),
        lastDeliveredAt: DateTime(2026, 9, 25, 20, 1),
        check: ReminderFireCheck.beforeReminderTime,
      ),
      (
        name:
            'a day that already had its digest gets no second one '
            '(BR-REMINDER-004)',
        reminder: _on2000,
        now: DateTime(2026, 9, 26, 22),
        lastDeliveredAt: DateTime(2026, 9, 26, 20, 1),
        check: ReminderFireCheck.alreadyDeliveredToday,
      ),
      (
        name:
            'a delivery read back in UTC is compared on the local date '
            '(ADR-008)',
        reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 0),
        now: DateTime(2026, 9, 26, 22),
        lastDeliveredAt: deliveredInUtc,
        check: ReminderFireCheck.alreadyDeliveredToday,
      ),
    ];
    for (final c in cases) {
      test(c.name, () {
        expect(
          reminderFireCheckOf(
            reminder: c.reminder,
            now: c.now,
            lastDeliveredAt: c.lastDeliveredAt,
          ),
          c.check,
        );
      });
    }
  });
}

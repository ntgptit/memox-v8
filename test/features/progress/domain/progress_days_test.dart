import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';

// BR-PROGRESS-003, BR-PROGRESS-011, BR-PROGRESS-013, BR-PROGRESS-015: the
// local days of one read (Progress spec §5.1).

void main() {
  const hanoi = Duration(hours: 7);

  DateTime todayOf(DateTime now, Duration offset) {
    final days = ProgressDays.of(now, offset);
    return days.dateOf(days.today);
  }

  test('23:30 and 00:30 local fall on two days (BR-PROGRESS-011)', () {
    // 23:30 on 25 September and 00:30 on 26 September in Hanoi.
    final evening = ProgressDays.of(DateTime.utc(2026, 9, 25, 16, 30), hanoi);
    final night = ProgressDays.of(DateTime.utc(2026, 9, 25, 17, 30), hanoi);

    expect(night.today - evening.today, 1);
    expect(evening.dateOf(evening.today), DateTime(2026, 9, 25));
    expect(night.dateOf(night.today), DateTime(2026, 9, 26));
  });

  test('one instant falls on the day of the offset it is read at: +7, -5, '
      '+14, -12 (BR-PROGRESS-011)', () {
    final instant = DateTime.utc(2026, 9, 25, 2);

    expect(todayOf(instant, hanoi), DateTime(2026, 9, 25));
    expect(todayOf(instant, const Duration(hours: -5)), DateTime(2026, 9, 24));
    expect(todayOf(instant, const Duration(hours: 14)), DateTime(2026, 9, 25));
    expect(todayOf(instant, const Duration(hours: -12)), DateTime(2026, 9, 24));
  });

  test('the week is today and the six days before, the month today and the '
      '29 before, across the end of a year (BR-PROGRESS-003, '
      'BR-PROGRESS-015)', () {
    // Noon on 3 January 2027 in Hanoi.
    final days = ProgressDays.of(DateTime.utc(2027, 1, 3, 5), hanoi);

    expect(days.dateOf(days.weekStart), DateTime(2026, 12, 28));
    expect(days.dateOf(days.monthStart), DateTime(2026, 12, 5));
    expect(days.today - days.weekStart + 1, 7);
    expect(days.today - days.monthStart + 1, 30);
  });

  test('across the end of a month, the week keeps seven days '
      '(BR-PROGRESS-015)', () {
    final days = ProgressDays.of(DateTime.utc(2026, 10, 2, 3), hanoi);

    expect(
      [
        for (var day = days.weekStart; day <= days.today; day++)
          days.dateOf(day),
      ],
      [
        DateTime(2026, 9, 26),
        DateTime(2026, 9, 27),
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 29),
        DateTime(2026, 9, 30),
        DateTime(2026, 10),
        DateTime(2026, 10, 2),
      ],
    );
  });

  test('the snapshot holds until the next local midnight, an instant '
      '(BR-PROGRESS-003)', () {
    final east = ProgressDays.of(DateTime.utc(2026, 9, 25, 16, 30), hanoi);
    final west = ProgressDays.of(
      DateTime.utc(2026, 9, 25, 2),
      const Duration(hours: -5),
    );

    // Midnight of 26 September in Hanoi; midnight of 25 September at -5.
    expect(east.validUntil, DateTime.utc(2026, 9, 25, 17));
    expect(west.validUntil, DateTime.utc(2026, 9, 25, 5));
    expect(east.validUntil.isUtc, isTrue);
  });
}

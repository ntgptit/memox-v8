import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

// UC-PROGRESS-001: Today, the last seven days and the current streak
// (BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016; Progress spec §5.3).

void main() {
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  /// A day [ago] days before today with [cards] reviewing card-days.
  ActiveDay active(int ago, {int learning = 0, int cards = 1}) =>
      ActiveDay(day: days.today - ago, learning: learning, reviewing: cards);

  /// The overview of a history with [rows], read as the repository reads it:
  /// every day for the streak, the last seven with their split.
  ProgressOverview overviewOf(List<ActiveDay> rows) => progressOverviewOf(
    activeDays: [for (final row in rows) row.day],
    week: [
      for (final row in rows)
        if (row.day >= days.weekStart) row,
    ],
    days: days,
  );

  test('Today carries its card-days split into Learning and Reviewing, and '
      'a day without activity is zero (BR-PROGRESS-014)', () {
    final studied = overviewOf([active(0, learning: 2, cards: 3)]).today;
    final quiet = overviewOf([active(1)]).today;

    expect(studied.date, DateTime(2026, 9, 25));
    expect((studied.learning, studied.reviewing, studied.total), (2, 3, 5));
    expect((quiet.learning, quiet.reviewing, quiet.total), (0, 0, 0));
  });

  test('the last seven days are seven, oldest first and today last, a day '
      'without activity as zero; an older day is not among them '
      '(BR-PROGRESS-015)', () {
    final seven = overviewOf([
      active(7, cards: 9),
      active(6, cards: 1),
      active(3, learning: 1, cards: 2),
      active(0, cards: 4),
    ]).lastSevenDays;

    expect(
      [for (final day in seven) day.date],
      [for (var n = 19; n <= 25; n++) DateTime(2026, 9, n)],
    );
    expect([for (final day in seven) day.total], [1, 0, 0, 3, 0, 0, 4]);
  });

  test('the streak counts back from today when today has activity, past '
      'the seven days with no cap (BR-PROGRESS-016)', () {
    final streak = overviewOf([for (var ago = 9; ago >= 0; ago--) active(ago)])
        .streak;

    expect((streak.days, streak.state), (10, StreakState.includesToday));
  });

  test('a day without activity ends the streak (BR-PROGRESS-016)', () {
    final streak = overviewOf([active(3), active(1), active(0)]).streak;

    expect((streak.days, streak.state), (2, StreakState.includesToday));
  });

  test('with nothing yet today, a streak that reached yesterday is held, '
      'not lost (BR-PROGRESS-016; UC-PROGRESS-001 A1)', () {
    final overview = overviewOf([active(2), active(1)]);

    expect(overview.today.total, 0);
    expect(
      (overview.streak.days, overview.streak.state),
      (2, StreakState.heldFromYesterday),
    );
  });

  test('with neither today nor yesterday the streak is 0 and lost, and the '
      'last active day names when it ended (BR-PROGRESS-016)', () {
    final overview = overviewOf([active(4), active(3)]);

    expect(
      (overview.streak.days, overview.streak.state),
      (0, StreakState.lost),
    );
    expect(overview.lastActiveDay, DateTime(2026, 9, 22));
    expect(overview.hasLifetimeActivity, isTrue);
  });

  test('never studied: no streak, no last active day and seven zero days '
      '(UC-PROGRESS-001 A2)', () {
    final overview = overviewOf(const []);

    expect(
      (overview.streak.days, overview.streak.state),
      (0, StreakState.never),
    );
    expect(overview.lastActiveDay, isNull);
    expect(overview.hasLifetimeActivity, isFalse);
    expect(
      [for (final day in overview.lastSevenDays) day.total],
      [0, 0, 0, 0, 0, 0, 0],
    );
  });
}

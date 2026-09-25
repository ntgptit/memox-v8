import 'package:memox/features/progress/domain/models/progress_days_model.dart';

/// A day of the last seven with activity: its card-days split into Learning
/// and Reviewing (BR-PROGRESS-011, BR-PROGRESS-014).
final class ActiveDay {
  const ActiveDay({
    required this.day,
    required this.learning,
    required this.reviewing,
  });

  /// Days since 1970-01-01 at the read's offset ([ProgressDays.today]).
  final int day;
  final int learning;
  final int reviewing;
}

/// One day of the overview, zero when nothing was studied
/// (BR-PROGRESS-014, BR-PROGRESS-015).
final class DayActivity {
  const DayActivity({
    required this.date,
    required this.learning,
    required this.reviewing,
  });

  final DateTime date;
  final int learning;
  final int reviewing;

  /// Every card-day of the day: the split always adds up (BR-PROGRESS-014).
  int get total => learning + reviewing;
}

/// How the current streak stands, as the kit names it (BR-PROGRESS-016).
enum StreakState {
  /// Today has activity.
  includesToday,

  /// Nothing yet today, but yesterday had activity: the streak holds.
  heldFromYesterday,

  /// Neither day had activity, after some study before.
  lost,

  /// No activity ever.
  never,
}

final class CurrentStreak {
  const CurrentStreak({required this.days, required this.state});

  /// Days that follow each other back from the anchor; no cap
  /// (BR-PROGRESS-016).
  final int days;

  final StreakState state;
}

/// The overview of UC-PROGRESS-001: Today, the last seven days and the
/// current streak, all from one snapshot (BR-PROGRESS-013).
final class ProgressOverview {
  const ProgressOverview({
    required this.today,
    required this.lastSevenDays,
    required this.streak,
    required this.lastActiveDay,
  });

  final DayActivity today;

  /// Exactly seven days, oldest first, today last (BR-PROGRESS-015).
  final List<DayActivity> lastSevenDays;

  final CurrentStreak streak;

  /// The latest day with activity, the day a lost streak ended; null only
  /// when nothing was ever studied.
  final DateTime? lastActiveDay;

  bool get hasLifetimeActivity => streak.state != StreakState.never;
}

/// The overview from the history (Progress spec §5.3): [activeDays], every
/// local day with activity up to today, oldest first, for the streak; and
/// [week], the days of the last seven with activity, for Today and the bars.
ProgressOverview progressOverviewOf({
  required List<int> activeDays,
  required List<ActiveDay> week,
  required ProgressDays days,
}) {
  final byDay = {for (final row in week) row.day: row};
  DayActivity activityOf(int day) => DayActivity(
    date: days.dateOf(day),
    learning: byDay[day]?.learning ?? 0,
    reviewing: byDay[day]?.reviewing ?? 0,
  );
  return ProgressOverview(
    today: activityOf(days.today),
    lastSevenDays: [
      for (var day = days.weekStart; day <= days.today; day++) activityOf(day),
    ],
    streak: _streakOf(activeDays.toSet(), today: days.today),
    lastActiveDay: activeDays.isEmpty ? null : days.dateOf(activeDays.last),
  );
}

/// BR-PROGRESS-016: anchored today when today has activity, else yesterday
/// when yesterday has; with no anchor the streak is 0.
CurrentStreak _streakOf(Set<int> active, {required int today}) {
  if (active.isEmpty) {
    return const CurrentStreak(days: 0, state: StreakState.never);
  }
  final anchor = active.contains(today) ? today : today - 1;
  if (!active.contains(anchor)) {
    return const CurrentStreak(days: 0, state: StreakState.lost);
  }
  var days = 0;
  while (active.contains(anchor - days)) {
    days++;
  }
  return CurrentStreak(
    days: days,
    state: anchor == today
        ? StreakState.includesToday
        : StreakState.heldFromYesterday,
  );
}

import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// The four sets of BR-STUDY-068 over a `card_schedule` row, as the SQL the
/// `.drift` queries take through their `$` placeholders (flutter-drift skill,
/// level 2): the one SQL copy of the rule (DEV-221). `dueStateOf` in the srs
/// domain is its Dart twin; `due_state_parity_test.dart` keeps them equal.
/// [startOfToday] is the local day's start at [now], computed once by the
/// caller (BR-STUDY-074).
final class CardDueSql {
  CardDueSql._();

  /// BR-CARD-007: not learned yet.
  static Expression<bool> isNew(CardScheduleTable s) => s.learnedAt.isNull();

  static Expression<bool> _isLearned(CardScheduleTable s) =>
      s.learnedAt.isNotNull();

  /// Learned and due before the start of the local day (BR-STUDY-067).
  static Expression<bool> isOverdue(
    CardScheduleTable s,
    DateTime startOfToday,
  ) => _isLearned(s) & s.dueAt.isSmallerThanValue(startOfToday);

  /// Learned and due from the start of the local day up to [now].
  static Expression<bool> isDueToday(
    CardScheduleTable s, {
    required DateTime now,
    required DateTime startOfToday,
  }) =>
      _isLearned(s) &
      s.dueAt.isBiggerOrEqualValue(startOfToday) &
      s.dueAt.isSmallerOrEqualValue(now);

  /// Learned and due at [now] or before: Overdue with Due today, the
  /// Reviewing set of BR-STUDY-051.
  static Expression<bool> isDue(CardScheduleTable s, DateTime now) =>
      _isLearned(s) & s.dueAt.isSmallerOrEqualValue(now);

  /// Learned and due after [now]: resting (BR-STUDY-068).
  static Expression<bool> isScheduled(CardScheduleTable s, DateTime now) =>
      _isLearned(s) & s.dueAt.isBiggerThanValue(now);
}

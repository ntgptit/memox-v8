import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';

part 'progress_dao.g.dart';

/// A day of the last seven with activity: its Learning and Reviewing
/// card-days.
typedef ActiveDayRow = ({int day, int learning, int reviewing});

/// One range's four numbers.
typedef CountsRow = ({int cards, int days, int learning, int reviewing});

/// A row of a level: a deck with its numbers for the week and the month; the
/// level's total when [deckId] is null (Progress spec D5).
typedef LevelRow = ({
  String? deckId,
  String? name,
  CountsRow week,
  CountsRow month,
});

/// The reads of the Progress screen (Progress spec §6,
/// `progress_queries.drift`). They write nothing (BR-PROGRESS-007,
/// BR-PROGRESS-009).
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/progress_queries.drift',
    'package:memox/core/database/queries/deck_queries.drift',
  },
)
final class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.attachedDatabase);

  /// Every local day with activity up to today, oldest first, folded in
  /// SQLite: the streak's days (UC-PROGRESS-001 step 2, BR-PROGRESS-016).
  Future<List<int>> activeDays(ProgressDays days) =>
      progressActiveDays(days.utcOffset.inSeconds, days.today).get();

  /// The days of the last seven with activity, with their Learning and
  /// Reviewing card-days: Today and the bars (BR-PROGRESS-014,
  /// BR-PROGRESS-015).
  Future<List<ActiveDayRow>> weekActivity(ProgressDays days) async {
    final rows = await progressWeekActivity(
      days.utcOffset.inSeconds,
      days.weekStart,
      days.today,
    ).get();
    return [
      for (final row in rows)
        (day: row.day, learning: row.learning, reviewing: row.reviewing),
    ];
  }

  /// Every active root deck with the numbers of its whole tree, grouped by
  /// `root_id`, and the library's total from the same statement
  /// (BR-PROGRESS-002, BR-PROGRESS-004).
  Future<List<LevelRow>> rootLevel(ProgressDays days) async {
    final rows = await progressRootLevel(
      days.utcOffset.inSeconds,
      days.monthStart,
      days.today,
      days.weekStart,
    ).get();
    return [for (final row in rows) _levelRowOf(row)];
  }

  /// Every active direct child of [deckId] with the numbers of its subtree,
  /// and the total of [deckId]'s whole subtree from the same statement
  /// (BR-PROGRESS-002, BR-PROGRESS-004).
  Future<List<LevelRow>> childLevel(String deckId, ProgressDays days) async {
    final rows = await progressChildLevel(
      deckId,
      days.utcOffset.inSeconds,
      days.monthStart,
      days.today,
      days.weekStart,
    ).get();
    return [for (final row in rows) _levelRowOf(row)];
  }

  /// [deckId] and every deck above it, root first; none when [deckId] is not
  /// an active deck (UC-PROGRESS-002 E2).
  Future<List<Deck>> deckPath(String deckId) => deckAndAncestors(deckId).get();

  /// Fires once when listened to, then after every write to the history,
  /// the cards or the decks (BR-PROGRESS-008).
  Stream<void> changes() => tableChanges(attachedDatabase, [
    attachedDatabase.reviewLog,
    attachedDatabase.card,
    attachedDatabase.deck,
  ]);
}

/// A deck with no activity has no `tiles` row: its numbers are zero.
LevelRow _levelRowOf(ProgressLevelRow row) => (
  deckId: row.deckId,
  name: row.name,
  week: (
    cards: row.weekCards ?? 0,
    days: row.weekDays ?? 0,
    learning: row.weekLearning ?? 0,
    reviewing: row.weekReviewing ?? 0,
  ),
  month: (
    cards: row.monthCards ?? 0,
    days: row.monthDays ?? 0,
    learning: row.monthLearning ?? 0,
    reviewing: row.monthReviewing ?? 0,
  ),
);

import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/card_due_sql.dart';

part 'reminder_workload_dao.g.dart';

/// Row access for the reminder's workload (`deck_queries.drift`). It returns
/// Drift rows, never domain values.
@DriftAccessor(
  include: {'package:memox/core/database/queries/deck_queries.drift'},
)
final class ReminderWorkloadDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderWorkloadDaoMixin {
  ReminderWorkloadDao(super.attachedDatabase);

  /// Every root deck outside the Trash with the counts of its whole tree,
  /// grouped by `root_id` (BR-REMINDER-007): the statement the Library's
  /// root level and Study Home read, so the reminder counts what they show
  /// (reminders spec D8).
  Future<List<DeckTileRow>> rootDeckRows({
    required DateTime now,
    required DateTime startOfToday,
  }) => deckLevelOfRoots(
    (c, k, cs) => CardDueSql.isNew(cs),
    (c, k, cs) => CardDueSql.isOverdue(cs, startOfToday),
    (c, k, cs) =>
        CardDueSql.isDueToday(cs, now: now, startOfToday: startOfToday),
    (c, k, cs) => CardDueSql.isDue(cs, now),
  ).get();
}

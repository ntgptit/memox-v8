import 'package:memox/core/database/app_database.dart';

/// Row access for the reminder's workload. It returns Drift rows, never
/// domain values.
final class ReminderWorkloadDao {
  ReminderWorkloadDao(this._db);

  final AppDatabase _db;

  /// Every root deck outside the Trash with the counts of its whole tree,
  /// grouped by `root_id` (BR-REMINDER-007): the statement the Library's
  /// root level and Study Home read, so the reminder counts what they show
  /// (reminders spec D8).
  Future<List<DeckTileRow>> rootDeckRows({
    required DateTime now,
    required DateTime startOfToday,
  }) => _db.deckLevelOfRoots(startOfToday, now).get();
}

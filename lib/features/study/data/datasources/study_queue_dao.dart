import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// `study_queue_items.status` of a row still to serve (BR-STUDY-007).
const _pending = 'pending';

/// Row access for `study_queue_items`. It returns Drift rows and card ids,
/// never domain values, and runs inside the caller's transaction.
final class StudyQueueDao {
  StudyQueueDao(this._db);

  final AppDatabase _db;

  /// Round 1 of [mode]: [cardIds] in serving order, each with its entry of
  /// [directions] when there are directions (BR-MODE-015).
  Future<void> insertFirstRound(
    String sessionId,
    String mode,
    List<String> cardIds, {
    List<String>? directions,
  }) => _db.batch(
    (batch) => batch.insertAll(_db.studyQueueItems, [
      for (final (position, cardId) in cardIds.indexed)
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode,
          cardId: cardId,
          position: position,
          status: _pending,
          direction: Value(directions?[position]),
        ),
    ]),
  );
}

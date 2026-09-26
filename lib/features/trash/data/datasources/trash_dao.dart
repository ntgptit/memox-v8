import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

/// Row access for the Trash (`trash_queries.drift`). It returns Drift rows,
/// never domain values, and runs inside the caller's transaction.
final class TrashDao {
  TrashDao(this._db);

  final AppDatabase _db;

  /// Fires once, then after every write to the batches, the decks or the
  /// cards: the Trash follows a delete, a restore and a purge.
  Stream<void> entryChanges() =>
      tableChanges(_db, [_db.deleteBatches, _db.deck, _db.card]);

  Future<List<TrashDeckEntryRow>> deckEntryRows() =>
      _db.trashDeckEntries().get();

  Future<List<TrashCardEntryRow>> cardEntryRows() =>
      _db.trashCardEntries().get();

  Future<List<TrashForestRow>> forestRows() => _db.trashDeckForest().get();

  /// The batches a purge takes: [chosen] ones that still exist, and every
  /// one deleted at or before [cutoff], oldest first (BR-TRASH-009,
  /// BR-TRASH-010).
  Future<List<DeleteBatch>> purgeCandidates({
    required Set<String> chosen,
    required DateTime cutoff,
  }) =>
      (_db.select(_db.deleteBatches)
            ..where(
              (batch) =>
                  batch.id.isIn(chosen) |
                  batch.deletedAt.isSmallerOrEqualValue(cutoff),
            )
            ..orderBy([
              (batch) => OrderingTerm(expression: batch.deletedAt),
              (batch) => OrderingTerm(expression: batch.id),
            ]))
          .get();

  /// What still sits in the decks of [batchId] and is not of it: another
  /// batch's id, or null for an active row (BR-TRASH-010).
  Future<List<String?>> blockersOf(String batchId) =>
      _db.trashBlockersOf(batchId).get();

  /// [batchId] goes for good: the keys delete its decks and cards, and
  /// theirs everything that hangs on them (BR-TRASH-010).
  Future<void> purge(String batchId) => (_db.delete(
    _db.deleteBatches,
  )..where((batch) => batch.id.equals(batchId))).go();
}

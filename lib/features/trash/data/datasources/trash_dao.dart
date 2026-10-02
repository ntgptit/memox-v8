import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/id_chunks.dart';
import 'package:memox/core/database/table_changes.dart';

part 'trash_dao.g.dart';

/// Row access for the Trash (`trash_queries.drift`). It returns Drift rows,
/// never domain values, and runs inside the caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/trash_queries.drift'},
)
final class TrashDao extends DatabaseAccessor<AppDatabase>
    with _$TrashDaoMixin {
  TrashDao(super.attachedDatabase);

  /// Fires once, then after every write to the batches, the decks or the
  /// cards: the Trash follows a delete, a restore and a purge.
  Stream<void> entryChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.deleteBatches,
    attachedDatabase.deck,
    attachedDatabase.card,
  ]);

  Future<List<TrashDeckEntryRow>> deckEntryRows() => trashDeckEntries().get();

  Future<List<TrashCardEntryRow>> cardEntryRows() => trashCardEntries().get();

  Future<List<TrashForestRow>> forestRows() => trashDeckForest().get();

  /// The batches a purge takes: [chosen] ones that still exist, and every
  /// one deleted at or before [cutoff], oldest first (BR-TRASH-009,
  /// BR-TRASH-010). [chosen] is read in chunks, each batch once (BE-C2).
  Future<List<DeleteBatch>> purgeCandidates({
    required Set<String> chosen,
    required DateTime cutoff,
  }) async {
    final byId = <String, DeleteBatch>{
      for (final batch in await deleteBatchesDeletedBy(cutoff).get())
        batch.id: batch,
      for (final chunk in idChunks(chosen))
        for (final batch in await deleteBatchesIn(chunk).get()) batch.id: batch,
    };
    return byId.values.toList()..sort((a, b) {
      final byTime = a.deletedAt.compareTo(b.deletedAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }

  /// What still sits in the decks of [batchId] and is not of it: another
  /// batch's id, or null for an active row (BR-TRASH-010).
  Future<List<String?>> blockersOf(String batchId) =>
      trashBlockersOf(batchId).get();

  /// [batchId] goes for good: the keys delete its decks and cards, and
  /// theirs everything that hangs on them (BR-TRASH-010).
  Future<void> purge(String batchId) => purgeDeleteBatch(batchId);
}

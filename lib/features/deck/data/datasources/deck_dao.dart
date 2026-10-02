import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

part 'deck_dao.g.dart';

/// Row access for `deck` (`deck_row_queries.drift`). It returns Drift rows,
/// never domain entities, and runs inside the caller's transaction:
/// `DeckRepositoryImpl` owns that. The level, path, move-target and
/// deletion-summary reads are `deck_queries.drift`'s, still on
/// [AppDatabase] while other features share their result classes.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/deck_row_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
    'package:memox/core/database/queries/delete_batch_queries.drift',
  },
)
final class DeckDao extends DatabaseAccessor<AppDatabase> with _$DeckDaoMixin {
  DeckDao(super.attachedDatabase);

  /// An active deck: a deck in the Trash is out of reach of every write
  /// (spec §8).
  Future<Deck?> findRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// The active decks under [parentId] in manual order, `(sibling_position,
  /// id)` (BR-SRS-007); a null parent selects the roots.
  Future<List<Deck>> siblingRows(String? parentId) =>
      liveSiblingDecks(parentId).get();

  Future<void> rename(String id, String name, DateTime now) =>
      renameLiveDeck(name, now, id);

  Future<void> setSiblingPosition(String id, int position, DateTime now) =>
      setLiveDeckSiblingPosition(position, now, id);

  /// The decks under [parentId], the roots when it is null, with the counts
  /// of their subtrees: one statement per emission (`deck_queries.drift`).
  Stream<List<DeckTileRow>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  }) {
    if (parentId == null) {
      return attachedDatabase.deckLevelOfRoots(startOfToday, now).watch();
    }
    return attachedDatabase
        .deckLevelOfChildren(parentId, startOfToday, now)
        .watch();
  }

  /// [id] and every deck above it, root first; empty when [id] is not an
  /// active deck.
  Stream<List<Deck>> watchDeckAndAncestors(String id) =>
      attachedDatabase.deckAndAncestors(id).watch();

  /// The decks a move of [id] may pick, and the decks on their paths.
  Stream<List<DeckForestRow>> watchMoveTargetRows(
    String id, {
    required int maxDepth,
  }) => attachedDatabase.deckMoveTargets(id, false, maxDepth).watch();

  /// The decks a restore of [itemId], the item root of a batch, may pick,
  /// and the decks on their paths (BR-TRASH-006).
  Future<List<DeckForestRow>> restoreTargetRows(
    String itemId, {
    required int maxDepth,
  }) => attachedDatabase.deckMoveTargets(itemId, true, maxDepth).get();

  /// Fires once, then after every write to the decks or the batches: where
  /// the decks of a Trash selection may go follows both (E2).
  Stream<void> restoreTargetChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.deck,
    attachedDatabase.deleteBatches,
  ]);

  /// One statement (`deck_queries.drift`); null when [id] is not an active
  /// deck.
  Future<DeckDeletionSummaryResult?> deletionSummary(String id) =>
      attachedDatabase.deckDeletionSummary(id).getSingleOrNull();

  Future<void> insert(DeckCompanion row) => createDeck(row);

  /// The batch of one deletion, with [id] as its item root (BR-TRASH-001).
  Future<void> insertBatch(String batchId, String id, DateTime now) =>
      insertDeleteBatch(batchId, 'deck', id, now);

  /// Puts [id] and every active deck under it in the batch [batchId], then
  /// every active card of those decks (BR-TRASH-001). A tombstone inside
  /// keeps its older batch (BR-TRASH-003). The walk is cycle-safe and never
  /// capped.
  Future<void> markSubtree(String id, String batchId) async {
    await markDeckSubtreeDeleted(id, batchId);
    await markCardsOfBatchDecksDeleted(batchId);
  }

  /// The item root of [batchId] when the batch holds a deck: the deck the
  /// person deleted, still marked with that batch (BR-TRASH-001). Null when
  /// the batch is gone or holds a card.
  Future<Deck?> itemRootOf(String batchId) =>
      deckOfBatch(batchId).getSingleOrNull();

  /// [id]'s row, active or in the Trash: a restore checks its item against
  /// the item's own root, which may be in the Trash too (BR-TRASH-006).
  Future<Deck?> rowInAnyState(String id) =>
      deckInAnyState(id).getSingleOrNull();

  /// Whether [id] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006).
  Future<bool> isInTrash(String id) => deckIsInTrash(id).getSingle();

  /// The rows of [batchId], decks and cards, lose their mark; then the batch
  /// row goes, which the key would otherwise cascade (BR-TRASH-007).
  Future<void> restoreBatch(String batchId) async {
    await unmarkDecksOfBatch(batchId);
    await unmarkCardsOfBatch(batchId);
    await dropDeleteBatch(batchId);
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004).
  Future<void> closeSessionsTouching(String batchId, DateTime now) =>
      closeSessionsTouchingBatch(now, batchId);

  Future<void> setContentType(String id, String contentType, DateTime now) =>
      setLiveDeckContentType(contentType, now, id);

  /// The end of the sibling group under [parentId]: the largest position
  /// plus one, `0` for a first child. `IS` makes a null parent select the
  /// roots (BR-SRS-007).
  Future<int> nextSiblingPosition(String? parentId) =>
      nextSiblingPositionUnder(parentId).getSingle();

  /// [id] and every deck above it, while they are active. Cycle-safe
  /// (`UNION`) and never capped, as schema.md asks of a tree walk.
  Future<List<String>> ancestorIds(String id) => liveAncestorIds(id).get();

  /// How many levels the subtree of [id] spans, itself included (a leaf is
  /// 1). A depth probe (schema.md): it walks at most [cap] levels, so an
  /// answer of [cap] means "at least [cap]". With the deepest level as [cap],
  /// that answer is already too deep under any parent.
  Future<int> subtreeHeight(String id, {required int cap}) async =>
      (await deckSubtreeHeight(id, cap).getSingle())!;

  /// What [id] holds now: `deck` with a live sub-deck, `card` with a live
  /// card, `unset` with neither (BR-DECK-006, BR-DECK-015). Tombstones do not
  /// count, as in invariants 2 and 29.
  Future<String> contentTypeFromChildren(String id) =>
      deckContentFromChildren(id).getSingle();

  /// Puts [id] under [parentId] at [siblingPosition], and gives its whole
  /// subtree [rootId] and a depth shifted by [depthShift] (BR-DECK-018). The
  /// subtree walk is cycle-safe and never capped.
  Future<void> moveSubtree(
    String id, {
    required String parentId,
    required String rootId,
    required int depthShift,
    required int siblingPosition,
    required DateTime now,
  }) async {
    await placeLiveDeck(parentId, siblingPosition, now, id);
    await reRootDeckSubtree(id, rootId, depthShift, now);
  }
}

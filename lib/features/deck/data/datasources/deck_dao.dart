import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

/// Row access for `deck`. It returns Drift rows, never domain entities, and
/// runs inside the caller's transaction: `DeckRepositoryImpl` owns that.
final class DeckDao {
  DeckDao(this._db);

  final AppDatabase _db;

  /// An active deck: a deck in the Trash is out of reach of every write
  /// (spec §8).
  Future<Deck?> findRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// The active decks under [parentId] in manual order, `(sibling_position,
  /// id)` (BR-SRS-007); a null parent selects the roots.
  Future<List<Deck>> siblingRows(String? parentId) =>
      (_db.select(_db.deck)
            ..where(
              (deck) =>
                  deck.parentId.isExp(Variable<String>(parentId)) &
                  deck.deleteBatchId.isNull(),
            )
            ..orderBy([
              (deck) => OrderingTerm(expression: deck.siblingPosition),
              (deck) => OrderingTerm(expression: deck.id),
            ]))
          .get();

  Future<void> rename(String id, String name, DateTime now) =>
      (_db.update(_db.deck)..where((deck) => deck.id.equals(id))).write(
        DeckCompanion(name: Value(name), updatedAt: Value(now)),
      );

  Future<void> setSiblingPosition(String id, int position, DateTime now) =>
      (_db.update(_db.deck)..where((deck) => deck.id.equals(id))).write(
        DeckCompanion(siblingPosition: Value(position), updatedAt: Value(now)),
      );

  /// The decks under [parentId], the roots when it is null, with the counts
  /// of their subtrees: one statement per emission (`deck_queries.drift`).
  Stream<List<DeckTileRow>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  }) {
    if (parentId == null) {
      return _db.deckLevelOfRoots(startOfToday, now).watch();
    }
    return _db.deckLevelOfChildren(parentId, startOfToday, now).watch();
  }

  /// [id] and every deck above it, root first; empty when [id] is not an
  /// active deck.
  Stream<List<Deck>> watchDeckAndAncestors(String id) =>
      _db.deckAndAncestors(id).watch();

  /// The decks a move of [id] may pick, and the decks on their paths.
  Stream<List<DeckForestRow>> watchMoveTargetRows(
    String id, {
    required int maxDepth,
  }) => _db.deckMoveTargets(id, false, maxDepth).watch();

  /// The decks a restore of [itemId], the item root of a batch, may pick,
  /// and the decks on their paths (BR-TRASH-006).
  Future<List<DeckForestRow>> restoreTargetRows(
    String itemId, {
    required int maxDepth,
  }) => _db.deckMoveTargets(itemId, true, maxDepth).get();

  /// Fires once, then after every write to the decks or the batches: where
  /// the decks of a Trash selection may go follows both (E2).
  Stream<void> restoreTargetChanges() =>
      tableChanges(_db, [_db.deck, _db.deleteBatches]);

  /// One statement (`deck_queries.drift`); null when [id] is not an active
  /// deck.
  Future<DeckDeletionSummaryResult?> deletionSummary(String id) =>
      _db.deckDeletionSummary(id).getSingleOrNull();

  Future<void> insert(DeckCompanion row) => _db.into(_db.deck).insert(row);

  /// The batch of one deletion, with [id] as its item root (BR-TRASH-001).
  Future<void> insertBatch(String batchId, String id, DateTime now) =>
      _db.insertDeleteBatch(batchId, 'deck', id, now);

  /// Puts [id] and every active deck under it in the batch [batchId], then
  /// every active card of those decks (BR-TRASH-001). A tombstone inside
  /// keeps its older batch (BR-TRASH-003). The walk is cycle-safe and never
  /// capped.
  Future<void> markSubtree(String id, String batchId) async {
    await _db.customUpdate(
      'WITH RECURSIVE subtree(id) AS ('
      ' SELECT ? UNION SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id'
      ' WHERE d.delete_batch_id IS NULL'
      ') UPDATE deck SET delete_batch_id = ? WHERE id IN (SELECT id FROM subtree)',
      variables: [Variable<String>(id), Variable<String>(batchId)],
      updates: {_db.deck},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE card SET delete_batch_id = ? WHERE delete_batch_id IS NULL'
      ' AND deck_id IN (SELECT id FROM deck WHERE delete_batch_id = ?)',
      variables: [Variable<String>(batchId), Variable<String>(batchId)],
      updates: {_db.card},
      updateKind: UpdateKind.update,
    );
  }

  /// The item root of [batchId] when the batch holds a deck: the deck the
  /// person deleted, still marked with that batch (BR-TRASH-001). Null when
  /// the batch is gone or holds a card.
  Future<Deck?> itemRootOf(String batchId) async {
    final row = await _db
        .customSelect(
          'SELECT d.* FROM delete_batches b JOIN deck d ON d.id = b.root_item_id'
          " AND d.delete_batch_id = b.id WHERE b.id = ? AND b.item_type = 'deck'",
          variables: [Variable<String>(batchId)],
          readsFrom: {_db.deleteBatches, _db.deck},
        )
        .getSingleOrNull();
    return row == null ? null : _db.deck.map(row.data);
  }

  /// [id]'s row, active or in the Trash: a restore checks its item against
  /// the item's own root, which may be in the Trash too (BR-TRASH-006).
  Future<Deck?> rowInAnyState(String id) => (_db.select(
    _db.deck,
  )..where((deck) => deck.id.equals(id))).getSingleOrNull();

  /// Whether [id] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006; `trash_queries.drift`).
  Future<bool> isInTrash(String id) => _db.deckIsInTrash(id).getSingle();

  /// The rows of [batchId], decks and cards, lose their mark; then the batch
  /// row goes, which the key would otherwise cascade (BR-TRASH-007).
  Future<void> restoreBatch(String batchId) async {
    await _db.customUpdate(
      'UPDATE deck SET delete_batch_id = NULL WHERE delete_batch_id = ?',
      variables: [Variable<String>(batchId)],
      updates: {_db.deck},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE card SET delete_batch_id = NULL WHERE delete_batch_id = ?',
      variables: [Variable<String>(batchId)],
      updates: {_db.card},
      updateKind: UpdateKind.update,
    );
    await (_db.delete(
      _db.deleteBatches,
    )..where((batch) => batch.id.equals(batchId))).go();
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004;
  /// `trash_queries.drift`).
  Future<void> closeSessionsTouching(String batchId, DateTime now) =>
      _db.closeSessionsTouchingBatch(now, batchId);

  Future<void> setContentType(String id, String contentType, DateTime now) =>
      (_db.update(_db.deck)..where((deck) => deck.id.equals(id))).write(
        DeckCompanion(contentType: Value(contentType), updatedAt: Value(now)),
      );

  /// The end of the sibling group under [parentId]: the largest position
  /// plus one, `0` for a first child. `IS` makes a null parent select the
  /// roots (BR-SRS-007).
  Future<int> nextSiblingPosition(String? parentId) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(sibling_position) + 1, 0) AS next '
          'FROM deck WHERE parent_id IS ?',
          variables: [Variable<String>(parentId)],
          readsFrom: {_db.deck},
        )
        .getSingle();
    return row.read<int>('next');
  }

  /// [id] and every deck above it, while they are active. Cycle-safe
  /// (`UNION`) and never capped, as schema.md asks of a tree walk.
  Future<List<String>> ancestorIds(String id) async {
    final rows = await _db
        .customSelect(
          'WITH RECURSIVE up(id, parent_id) AS ('
          ' SELECT id, parent_id FROM deck WHERE id = ? AND delete_batch_id IS NULL'
          ' UNION SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id'
          ' WHERE d.delete_batch_id IS NULL'
          ') SELECT id FROM up',
          variables: [Variable<String>(id)],
          readsFrom: {_db.deck},
        )
        .get();
    return [for (final row in rows) row.read<String>('id')];
  }

  /// How many levels the subtree of [id] spans, itself included (a leaf is
  /// 1). A depth probe (schema.md): it walks at most [cap] levels, so an
  /// answer of [cap] means "at least [cap]". With the deepest level as [cap],
  /// that answer is already too deep under any parent.
  Future<int> subtreeHeight(String id, {required int cap}) async {
    final row = await _db
        .customSelect(
          'WITH RECURSIVE down(id, height) AS ('
          ' SELECT id, 1 FROM deck WHERE id = ?'
          ' UNION ALL SELECT d.id, down.height + 1 FROM deck d'
          ' JOIN down ON d.parent_id = down.id WHERE down.height < ?'
          ') SELECT MAX(height) AS height FROM down',
          variables: [Variable<String>(id), Variable<int>(cap)],
          readsFrom: {_db.deck},
        )
        .getSingle();
    return row.read<int>('height');
  }

  /// What [id] holds now: `deck` with a live sub-deck, `card` with a live
  /// card, `unset` with neither (BR-DECK-006, BR-DECK-015). Tombstones do not
  /// count, as in invariants 2 and 29.
  Future<String> contentTypeFromChildren(String id) async {
    final row = await _db
        .customSelect(
          "SELECT CASE"
          " WHEN EXISTS (SELECT 1 FROM deck WHERE parent_id = ? AND delete_batch_id IS NULL) THEN 'deck'"
          " WHEN EXISTS (SELECT 1 FROM card WHERE deck_id = ? AND delete_batch_id IS NULL) THEN 'card'"
          " ELSE 'unset' END AS content_type",
          variables: [Variable<String>(id), Variable<String>(id)],
          readsFrom: {_db.deck, _db.card},
        )
        .getSingle();
    return row.read<String>('content_type');
  }

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
    await (_db.update(_db.deck)..where((deck) => deck.id.equals(id))).write(
      DeckCompanion(
        parentId: Value(parentId),
        siblingPosition: Value(siblingPosition),
        updatedAt: Value(now),
      ),
    );
    await _db.customUpdate(
      'WITH RECURSIVE subtree(id) AS ('
      ' SELECT ? UNION SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id'
      ') UPDATE deck SET root_id = ?, depth = depth + ?, updated_at = ?'
      ' WHERE id IN (SELECT id FROM subtree)',
      variables: [
        Variable<String>(id),
        Variable<String>(rootId),
        Variable<int>(depthShift),
        Variable<DateTime>(now),
      ],
      updates: {_db.deck},
      updateKind: UpdateKind.update,
    );
  }
}

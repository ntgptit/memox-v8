import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Row access for `deck`. It returns Drift rows, never domain entities, and
/// runs inside the caller's transaction: `DeckRepositoryImpl` owns that.
final class DeckDao {
  DeckDao(this._db);

  final AppDatabase _db;

  Future<Deck?> findRow(String id) => (_db.select(
    _db.deck,
  )..where((deck) => deck.id.equals(id))).getSingleOrNull();

  Future<void> insert(DeckCompanion row) => _db.into(_db.deck).insert(row);

  Future<void> delete(String id) =>
      (_db.delete(_db.deck)..where((deck) => deck.id.equals(id))).go();

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

  /// [id] and every deck above it. Cycle-safe (`UNION`) and never capped, as
  /// schema.md asks of a tree walk.
  Future<List<String>> ancestorIds(String id) async {
    final rows = await _db
        .customSelect(
          'WITH RECURSIVE up(id, parent_id) AS ('
          ' SELECT id, parent_id FROM deck WHERE id = ?'
          ' UNION SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id'
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

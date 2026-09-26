import 'package:memox/core/database/app_database.dart';

/// A row of `delete_batches` alone, for a test that marks rows by hand: the
/// key on `delete_batch_id` refuses an unknown batch (trash spec §5.4). A
/// second call with the same id changes nothing.
Future<void> insertDeleteBatch(
  AppDatabase db,
  String id, {
  required String itemType,
  required String rootItemId,
  int deletedAt = 0,
}) => db.customStatement(
  'INSERT OR IGNORE INTO delete_batches '
  '(id, item_type, root_item_id, deleted_at) VALUES (?, ?, ?, ?)',
  [id, itemType, rootItemId, deletedAt],
);

/// [deckId] in the Trash with every active deck and card under it, as one
/// batch, the way a delete leaves them (BR-TRASH-001, BR-TRASH-003), for a
/// test that needs tombstones without the delete path.
Future<void> trashDeckRows(
  AppDatabase db,
  String deckId, {
  String? batchId,
  int deletedAt = 0,
}) async {
  final batch = batchId ?? 'trash-$deckId';
  await insertDeleteBatch(
    db,
    batch,
    itemType: 'deck',
    rootItemId: deckId,
    deletedAt: deletedAt,
  );
  await db.customStatement(
    'WITH RECURSIVE subtree(id) AS (SELECT ? UNION '
    'SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id) '
    'UPDATE deck SET delete_batch_id = ? '
    'WHERE id IN (SELECT id FROM subtree) AND delete_batch_id IS NULL',
    [deckId, batch],
  );
  await db.customStatement(
    'UPDATE card SET delete_batch_id = ? WHERE delete_batch_id IS NULL '
    'AND deck_id IN (SELECT id FROM deck WHERE delete_batch_id = ?)',
    [batch, batch],
  );
}

/// [cardId] in the Trash as a batch of its own (BR-TRASH-001).
Future<void> trashCardRow(
  AppDatabase db,
  String cardId, {
  String? batchId,
  int deletedAt = 0,
}) async {
  final batch = batchId ?? 'trash-$cardId';
  await insertDeleteBatch(
    db,
    batch,
    itemType: 'card',
    rootItemId: cardId,
    deletedAt: deletedAt,
  );
  await db.customStatement('UPDATE card SET delete_batch_id = ? WHERE id = ?', [
    batch,
    cardId,
  ]);
}

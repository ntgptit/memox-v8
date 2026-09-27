import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/core/sync/sync_outbox.dart';

/// BE-E7 spec §4.3: every row the server has not acknowledged becomes the
/// commands that would have made it, in causal order, so the first sync
/// uploads the library before any later edit. Runs inside the v5 → v6
/// migration, where the TEMP collector does not exist yet.
Future<void> seedLibraryUpload(AppDatabase db) async {
  final outbox = SyncOutboxWriter(db);

  Future<void> command(
    String type,
    Map<String, Object?> payload,
    SyncEntityRef subject,
  ) => outbox.command(type, payload, subject: subject, drainChanges: false);

  for (final row
      in await db
          .customSelect(
            'SELECT id, name, scheduler_type FROM deck '
            'WHERE parent_id IS NULL AND server_version IS NULL ORDER BY sibling_position, id',
          )
          .get()) {
    final id = row.read<String>('id');
    await command(SyncCommandType.createRootDeck, {
      'id': id,
      'name': row.read<String>('name'),
      'schedulerType': row.read<String>('scheduler_type'),
    }, SyncEntityRef.deck(id));
  }
  for (final row
      in await db
          .customSelect(
            'SELECT id, parent_id, name FROM deck WHERE parent_id IS NOT NULL AND server_version IS NULL '
            'ORDER BY depth, parent_id, sibling_position, id',
          )
          .get()) {
    final id = row.read<String>('id');
    await command(SyncCommandType.createSubDeck, {
      'id': id,
      'parentId': row.read<String>('parent_id'),
      'name': row.read<String>('name'),
    }, SyncEntityRef.deck(id));
  }
  for (final row
      in await db
          .customSelect(
            'SELECT id, deck_id, front, back, example, hint, pronunciation FROM card '
            'WHERE server_version IS NULL ORDER BY deck_id, created_at, id',
          )
          .get()) {
    final id = row.read<String>('id');
    await command(SyncCommandType.createCard, {
      'id': id,
      'deckId': row.read<String>('deck_id'),
      'front': row.read<String>('front'),
      'back': row.read<String>('back'),
      'example': row.readNullable<String>('example'),
      'hint': row.readNullable<String>('hint'),
      'pronunciation': row.readNullable<String>('pronunciation'),
    }, SyncEntityRef.card(id));
  }
  for (final row
      in await db
          .customSelect(
            'SELECT id FROM card WHERE is_flagged = 1 AND server_version IS NULL ORDER BY id',
          )
          .get()) {
    await outbox.patch(
      SyncEntityType.card,
      row.read<String>('id'),
      SyncPatchGroup.flag,
      drainChanges: false,
    );
  }
  for (final row
      in await db
          .customSelect(
            'SELECT id FROM deck WHERE parent_id IS NULL AND study_config IS NOT NULL AND server_version IS NULL ORDER BY id',
          )
          .get()) {
    await outbox.patch(
      SyncEntityType.deck,
      row.read<String>('id'),
      SyncPatchGroup.studyOptions,
      drainChanges: false,
    );
  }
  // A batch whose root item is not marked with it is inconsistent: sending
  // it would trash something the device shows as active.
  for (final row
      in await db
          .customSelect(
            'SELECT b.id, b.item_type, b.root_item_id, b.deleted_at FROM delete_batches b '
            'WHERE b.server_version IS NULL AND ('
            "  (b.item_type = 'deck' AND EXISTS (SELECT 1 FROM deck d WHERE d.id = b.root_item_id AND d.delete_batch_id = b.id)) OR "
            "  (b.item_type = 'card' AND EXISTS (SELECT 1 FROM card c WHERE c.id = b.root_item_id AND c.delete_batch_id = b.id))"
            ') ORDER BY b.deleted_at, b.id',
          )
          .get()) {
    final batchId = row.read<String>('id');
    final itemId = row.read<String>('root_item_id');
    final deletedAt = toWireTime(row.read<DateTime>('deleted_at'));
    if (row.read<String>('item_type') == 'deck') {
      await command(SyncCommandType.deleteDeck, {
        'deckId': itemId,
        'batchId': batchId,
        'deletedAt': deletedAt,
      }, SyncEntityRef.deleteBatch(batchId));
    } else {
      await command(SyncCommandType.deleteCards, {
        'items': [
          {'cardId': itemId, 'batchId': batchId},
        ],
        'deletedAt': deletedAt,
      }, SyncEntityRef.deleteBatch(batchId));
    }
  }
}

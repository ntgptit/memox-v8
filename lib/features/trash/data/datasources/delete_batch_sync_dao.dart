import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

part 'delete_batch_sync_dao.g.dart';

/// Syncs `delete_batches`, the trash batches that trashed decks reference.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/sync_delete_batch_queries.drift',
  },
)
class DeleteBatchSyncDao extends DatabaseAccessor<AppDatabase>
    with _$DeleteBatchSyncDaoMixin, EntitySyncAdapter {
  DeleteBatchSyncDao(super.attachedDatabase);

  static const type = 'delete_batch';

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final batch = await syncDeleteBatchRow(id).getSingleOrNull();
    if (batch == null) {
      return null;
    }
    return {
      'id': batch.id,
      'itemType': batch.itemType,
      'rootItemId': batch.rootItemId,
      'deletedAt': toWireTime(batch.deletedAt)!
          .replaceFirst(RegExp(r'\.\d+Z$'), 'Z'),
    };
  }

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion) =>
      upsertSyncedDeleteBatch(
        DeleteBatchesCompanion.insert(
          id: row['id'] as String,
          itemType: row['itemType'] as String,
          rootItemId: row['rootItemId'] as String,
          deletedAt: fromWireTime(row['deletedAt'])!,
          serverVersion: Value(serverVersion),
        ),
      );

  @override
  Future<void> deleteFromServer(String id) => deleteSyncedDeleteBatch(id);

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      acknowledgeDeleteBatch(serverVersion, id);
}

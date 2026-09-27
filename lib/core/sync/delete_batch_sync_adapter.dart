import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

/// Syncs `delete_batches`, the trash batches that trashed decks reference.
class DeleteBatchSyncAdapter extends EntitySyncAdapter {
  DeleteBatchSyncAdapter(this._db);

  static const type = 'delete_batch';

  final AppDatabase _db;

  @override
  String get entityType => type;

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion) =>
      _db
          .into(_db.deleteBatches)
          .insertOnConflictUpdate(
            DeleteBatchesCompanion.insert(
              id: row['id'] as String,
              itemType: row['itemType'] as String,
              rootItemId: row['rootItemId'] as String,
              deletedAt: fromWireTime(row['deletedAt'])!,
              serverVersion: Value(serverVersion),
            ),
          );

  @override
  Future<void> deleteFromServer(String id) =>
      (_db.delete(_db.deleteBatches)..where((b) => b.id.equals(id))).go();
}

import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

/// Syncs `delete_batches`, the trash batches that trashed decks reference.
class DeleteBatchSyncAdapter implements EntitySyncAdapter {
  DeleteBatchSyncAdapter(this._db);

  static const type = 'delete_batch';

  final AppDatabase _db;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final batch = await (_db.select(
      _db.deleteBatches,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
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
  Future<void> upsertFromServer(Map<String, dynamic> row, int serverVersion) =>
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

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      (_db.update(_db.deleteBatches)..where((b) => b.id.equals(id))).write(
        DeleteBatchesCompanion(serverVersion: Value(serverVersion)),
      );
}

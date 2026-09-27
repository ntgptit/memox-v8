import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_outbox.dart';

/// Syncs `deck`. The server derives rootId and depth; the pulled values are
/// written as they come.
class DeckSyncAdapter implements EntitySyncAdapter {
  DeckSyncAdapter(this._db);

  static const type = 'deck';

  final AppDatabase _db;

  @override
  String get entityType => type;

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion) =>
      _db
          .into(_db.deck)
          .insertOnConflictUpdate(
            DeckCompanion.insert(
              id: row['id'] as String,
              name: row['name'] as String,
              parentId: Value(row['parentId'] as String?),
              rootId: row['rootId'] as String,
              depth: row['depth'] as int,
              contentType: Value(row['contentType'] as String),
              schedulerType: Value(row['schedulerType'] as String?),
              schedulerVersion: Value(row['schedulerVersion'] as int?),
              schedulerConfig: Value(row['schedulerConfig'] as String?),
              studyConfig: Value(row['studyConfig'] as String?),
              generation: Value(row['generation'] as int?),
              firstAnsweredAt: Value(fromWireTime(row['firstAnsweredAt'])),
              sourceTemplateId: Value(row['sourceTemplateId'] as String?),
              sourceTemplateVersion: Value(
                row['sourceTemplateVersion'] as int?,
              ),
              deleteBatchId: Value(row['deleteBatchId'] as String?),
              siblingPosition: row['siblingPosition'] as int,
              createdAt: fromWireTime(row['createdAt'])!,
              updatedAt: fromWireTime(row['updatedAt'])!,
              serverVersion: Value(serverVersion),
            ),
          );

  @override
  Future<void> deleteFromServer(String id) =>
      (_db.delete(_db.deck)..where((d) => d.id.equals(id))).go();

  @override
  Future<Map<String, Object?>?> readPatch(String id, String group) async {
    if (group != SyncPatchGroup.studyOptions) {
      return null;
    }
    final deck = await (_db.select(
      _db.deck,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    return deck == null ? null : {'studyConfig': deck.studyConfig};
  }
}

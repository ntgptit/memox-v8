import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/core/sync/sync_outbox.dart';
import 'package:memox/core/text/folded_text.dart';

/// Syncs `card`. The server sends no folded columns: they are this device's
/// search keys, computed here (BE-C5).
class CardSyncAdapter implements EntitySyncAdapter {
  CardSyncAdapter(this._db);

  final AppDatabase _db;

  @override
  String get entityType => SyncEntityType.card;

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion) {
    final front = row['front']! as String;
    final back = row['back']! as String;
    return _db
        .into(_db.card)
        .insertOnConflictUpdate(
          CardCompanion.insert(
            id: row['id']! as String,
            deckId: row['deckId']! as String,
            front: front,
            back: back,
            frontFolded: Value(foldText(front)),
            backFolded: Value(foldText(back)),
            isFlagged: Value((row['isFlagged'] as bool? ?? false) ? 1 : 0),
            example: Value(row['example'] as String?),
            hint: Value(row['hint'] as String?),
            pronunciation: Value(row['pronunciation'] as String?),
            deleteBatchId: Value(row['deleteBatchId'] as String?),
            createdAt: fromWireTime(row['createdAt'])!,
            updatedAt: fromWireTime(row['updatedAt'])!,
            serverVersion: Value(serverVersion),
          ),
        );
  }

  @override
  Future<void> deleteFromServer(String id) =>
      (_db.delete(_db.card)..where((c) => c.id.equals(id))).go();

  @override
  Future<Map<String, Object?>?> readPatch(String id, String group) async {
    final card = await (_db.select(
      _db.card,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (card == null) {
      return null;
    }
    return switch (group) {
      SyncPatchGroup.content => {
        'front': card.front,
        'back': card.back,
        'example': card.example,
        'hint': card.hint,
        'pronunciation': card.pronunciation,
      },
      SyncPatchGroup.flag => {'isFlagged': card.isFlagged == 1},
      _ => null,
    };
  }
}

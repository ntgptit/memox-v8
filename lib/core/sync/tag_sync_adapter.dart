import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_store.dart';

/// Syncs `tags` (library and study sync spec §3.2). A pulled tag whose name
/// a different local tag holds absorbs that tag: its links move over and it
/// is deleted, and since pulls skip the triggers, the moved cards and the
/// deleted tag are queued here.
class TagSyncAdapter implements EntitySyncAdapter {
  TagSyncAdapter(this._db, this._store, {this._now = DateTime.now});

  static const type = 'tag';
  static const _card = 'card';

  final AppDatabase _db;
  final SyncStore _store;
  final DateTime Function() _now;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final tag = await (_db.select(
      _db.tags,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (tag == null) {
      return null;
    }
    return {
      'id': tag.id,
      'name': tag.name,
      'nameFolded': tag.nameFolded,
      'createdAt': toWireTime(tag.createdAt)!
          .replaceFirst(RegExp(r'\.\d+Z$'), 'Z'),
    };
  }

  @override
  Future<void> upsertFromServer(
    Map<String, Object?> row,
    int serverVersion,
  ) async {
    final id = row['id'] as String;
    final nameFolded = row['nameFolded'] as String;
    final clash =
        await (_db.select(_db.tags)..where(
              (t) =>
                  t.ownerId.isNull() &
                  t.nameFolded.equals(nameFolded) &
                  t.id.equals(id).not(),
            ))
            .getSingleOrNull();
    final moved = clash == null ? const <String>[] : await _cardsOf(clash.id);
    if (clash != null) {
      // Deleted first: the unique name must be free before the pulled tag lands.
      await deleteFromServer(clash.id);
    }
    await _db
        .into(_db.tags)
        .insertOnConflictUpdate(
          TagsCompanion.insert(
            id: id,
            name: row['name'] as String,
            nameFolded: nameFolded,
            createdAt: fromWireTime(row['createdAt'])!,
            serverVersion: Value(serverVersion),
          ),
        );
    if (clash == null) {
      return;
    }
    final now = _now();
    for (final cardId in moved) {
      await _db
          .into(_db.cardTags)
          .insert(
            CardTagsCompanion.insert(cardId: cardId, tagId: id),
            mode: InsertMode.insertOrIgnore,
          );
      await _store.enqueue(_card, cardId, 'upsert', now);
    }
    await _store.enqueue(type, clash.id, 'delete', now);
    await _store.clearRejection(type, clash.id);
  }

  @override
  Future<void> deleteFromServer(String id) =>
      (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(
        TagsCompanion(serverVersion: Value(serverVersion)),
      );

  Future<List<String>> _cardsOf(String tagId) async => [
    for (final link in await (_db.select(
      _db.cardTags,
    )..where((l) => l.tagId.equals(tagId))).get())
      link.cardId,
  ];
}

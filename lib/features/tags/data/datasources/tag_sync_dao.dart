import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/text/folded_text.dart';

part 'tag_sync_dao.g.dart';

/// Syncs `tags` (library and study sync spec §3.2). A pulled tag whose name
/// a different local tag holds absorbs that tag: its links move over and it
/// is deleted, and since pulls skip the triggers, the moved cards and the
/// deleted tag are queued here. The local tag goes first because the folded
/// name is unique (BR-TAG-006), which drops its links, so the moved cards are
/// relinked with `INSERT OR IGNORE` rather than `mergeTagLinks` (DEV-173).
@DriftAccessor(
  include: {'package:memox/core/database/queries/sync_tag_queries.drift'},
)
class TagSyncDao extends DatabaseAccessor<AppDatabase>
    with _$TagSyncDaoMixin, EntitySyncAdapter {
  TagSyncDao(super.attachedDatabase, this._store, {this._now = DateTime.now});

  static const type = 'tag';
  static const _card = 'card';

  final SyncStore _store;
  final DateTime Function() _now;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final tag = await syncTagRow(id).getSingleOrNull();
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
    final name = row['name'] as String;
    // Folded here, never taken from the wire (schema.md, the foldText
    // contract; DEV-201): a client that folds differently still lands on the
    // one local tag of that name (BR-TAG-001).
    final nameFolded = foldText(name);
    final clash = await syncTagClashOf(nameFolded, id).getSingleOrNull();
    final moved = clash == null ? const <String>[] : await _cardsOf(clash.id);
    if (clash != null) {
      // Deleted first: the unique name must be free before the pulled tag lands.
      await deleteFromServer(clash.id);
    }
    await upsertSyncedTag(
      TagsCompanion.insert(
        id: id,
        name: name,
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
      await linkSyncedTagCard(cardId, id);
      await _store.enqueue(_card, cardId, 'upsert', now);
    }
    await _store.enqueue(type, clash.id, 'delete', now);
    await _store.clearRejection(type, clash.id);
  }

  @override
  Future<void> deleteFromServer(String id) => deleteSyncedTag(id);

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      acknowledgeTag(serverVersion, id);

  Future<List<String>> _cardsOf(String tagId) => syncCardsOfTag(tagId).get();
}

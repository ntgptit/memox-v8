import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

import '../../support/test_database.dart';

Map<String, Object?> _wire(String id, String name) => {
  'id': id,
  'name': name,
  'nameFolded': name.toLowerCase(),
  'createdAt': '2026-09-28T01:02:03Z',
};

void main() {
  late AppDatabase db;
  late SyncStore store;
  late TagSyncAdapter adapter;
  setUp(() {
    db = openTestDatabase();
    store = SyncStore(db);
    adapter = TagSyncAdapter(db, store, now: () => DateTime.utc(2026, 9, 28));
  });
  tearDown(() => db.close());

  Future<void> remote(Future<void> Function() body) =>
      store.applyingRemote(deferForeignKeys: true, body);

  test('a pulled tag reads back as the same wire row', () async {
    await remote(() => adapter.upsertFromServer(_wire('T', 'Verb'), 4));
    expect(await adapter.readRow('T'), _wire('T', 'Verb'));
    await adapter.markAcknowledged('T', 9);
    final row = await (db.select(
      db.tags,
    )..where((t) => t.id.equals('T'))).getSingle();
    expect(row.serverVersion, 9);
    await remote(() => adapter.deleteFromServer('T'));
    expect(await adapter.readRow('T'), isNull);
  });

  test('a pulled tag with a local tag\'s name absorbs it', () async {
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('K', 'R', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('L', 'verb', 'verb', 0)",
    );
    await db.customStatement(
      "INSERT INTO card_tags (card_id, tag_id) VALUES ('K', 'L')",
    );
    await store.recordRejection(
      'tag',
      'L',
      'TAG_NAME_TAKEN',
      DateTime.utc(2026),
    );
    await db.customStatement('DELETE FROM sync_outbox');

    await remote(() => adapter.upsertFromServer(_wire('P', 'Verb'), 5));

    expect(await db.select(db.tags).get(), hasLength(1));
    final links = await db.select(db.cardTags).get();
    expect(links.single.tagId, 'P');
    final queued = {
      for (final e in await db.select(db.syncOutbox).get())
        '${e.entityType}/${e.entityId}': e.op,
    };
    expect(queued, {'card/K': 'upsert', 'tag/L': 'delete'});
    expect(await store.rejections(), isEmpty);
  });
}

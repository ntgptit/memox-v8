import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/account_settings_sync_adapter.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/review_log_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

/// SB-S3: tags and card links converge across two devices (library and
/// study sync spec §3.2).
class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    final store = SyncStore(db);
    final cards = CardSyncDao(db);
    coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [
        DeleteBatchSyncAdapter(db),
        DeckSyncAdapter(db),
        TagSyncAdapter(db, store),
        cards,
        CardScheduleSyncDao(db, store),
        ReviewLogSyncAdapter(db),
        AccountSettingsSyncAdapter(db),
      ],
    );
  }
  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

Future<void> _root(AppDatabase db, String id) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, id],
);

Future<void> _card(AppDatabase db, String id, String deck) =>
    db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES (?, ?, 'f', 'b', 0, 0)",
      [id, deck],
    );

Future<void> _tag(AppDatabase db, String id, String name) => db.customStatement(
  'INSERT INTO tags (id, name, name_folded, created_at) VALUES (?, ?, lower(?), 0)',
  [id, name, name],
);

Future<void> _link(AppDatabase db, String card, String tag) =>
    db.customStatement(
      'INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)',
      [card, tag],
    );

Future<Set<String>> _links(AppDatabase db) async => {
  for (final l in await db.select(db.cardTags).get()) '${l.cardId}/${l.tagId}',
};

void main() {
  late FakeSyncServer server;
  late _Device a;
  late _Device b;
  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('a link and an unlink reach the other device', () async {
    await _root(a.db, 'R');
    await _card(a.db, 'K', 'R');
    await _tag(a.db, 'T', 'Verb');
    await _link(a.db, 'K', 'T');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    expect(await _links(b.db), {'K/T'});

    await a.db.customStatement("DELETE FROM card_tags WHERE card_id = 'K'");
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    expect(await _links(b.db), isEmpty);
  });

  test('a tag deleted on one device leaves the cards of the other', () async {
    await _root(a.db, 'R');
    await _card(a.db, 'K', 'R');
    await _tag(a.db, 'T', 'Verb');
    await _link(a.db, 'K', 'T');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();

    await a.db.customStatement("DELETE FROM tags WHERE id = 'T'");
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    expect(await b.db.select(b.db.tags).get(), isEmpty);
    expect(await _links(b.db), isEmpty);
  });

  test('the same name made on two devices merges into the first', () async {
    await _root(a.db, 'R');
    await _card(a.db, 'KA', 'R');
    await _tag(a.db, 'TA', 'Verb');
    await _link(a.db, 'KA', 'TA');
    await a.coordinator.runOnce();

    await _root(b.db, 'RB');
    await _card(b.db, 'KB', 'RB');
    await _tag(b.db, 'TB', 'verb');
    await _link(b.db, 'KB', 'TB');
    server.rejectNext['tag/TB'] = 'TAG_NAME_TAKEN'; // the fake has no name rule

    await b.coordinator.runOnce(); // TB refused; pull brings TA and KB back
    await b.coordinator.runOnce(); // KB (now TA) and TB's delete go up
    await a.coordinator.runOnce();

    for (final device in [a, b]) {
      expect((await device.db.select(device.db.tags).get()).map((t) => t.id), [
        'TA',
      ]);
      expect(await _links(device.db), {'KA/TA', 'KB/TA'});
      expect(await device.db.select(device.db.syncRejection).get(), isEmpty);
    }
    expect(await b.db.select(b.db.syncOutbox).get(), isEmpty);
  });
}

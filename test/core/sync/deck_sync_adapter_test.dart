import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';

Map<String, dynamic> _serverRoot(String id) => {
  'id': id,
  'name': 'From server',
  'parentId': null,
  'rootId': id,
  'depth': 1,
  'contentType': 'deck',
  'schedulerType': 'sm2',
  'schedulerVersion': 1,
  'schedulerConfig': null,
  'studyConfig': '{"cardLimit":10}',
  'generation': 2,
  'firstAnsweredAt': '2026-09-27T01:02:03Z',
  'sourceTemplateId': null,
  'sourceTemplateVersion': null,
  'deleteBatchId': null,
  'siblingPosition': 3,
  'createdAt': '2026-09-27T01:00:00Z',
  'updatedAt': '2026-09-27T01:05:00Z',
};

void main() {
  late AppDatabase db;
  late DeckSyncAdapter adapter;
  late SyncStore store;
  setUp(() {
    db = openTestDatabase();
    adapter = DeckSyncAdapter(db);
    store = SyncStore(db);
  });
  tearDown(() => db.close());

  test('a server row round-trips through Drift in the wire shape', () async {
    await store.applyingRemote(
      () => adapter.upsertFromServer(_serverRoot('R'), 9),
    );

    final row = await adapter.readRow('R');
    expect(row, _serverRoot('R'));
    final deck = await (db.select(
      db.deck,
    )..where((d) => d.id.equals('R'))).getSingle();
    expect(deck.serverVersion, 9);
    // Drift returns local DateTimes; compare the instant, not the zone.
    expect(
      deck.firstAnsweredAt!.isAtSameMomentAs(
        DateTime.utc(2026, 9, 27, 1, 2, 3),
      ),
      isTrue,
    );
  });

  test('applying server data queues nothing', () async {
    await store.applyingRemote(
      () => adapter.upsertFromServer(_serverRoot('R'), 1),
    );
    await store.applyingRemote(() => adapter.deleteFromServer('R'));

    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('an unknown row reads as null', () async {
    expect(await adapter.readRow('missing'), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/core/sync/sync_outbox.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late SyncStore store;
  setUp(() {
    db = openTestDatabase();
    store = SyncStore(db);
  });
  tearDown(() => db.close());

  test('the device id is created once and kept', () async {
    final first = await store.deviceId();
    expect(await store.deviceId(), first);
  });

  test('pending entities are patch targets and every affected id', () async {
    final outbox = SyncOutboxWriter(db);
    await outbox.patch(SyncEntityType.card, 'k1', SyncPatchGroup.flag);
    await outbox.command(SyncCommandType.moveDeck, {
      'deckId': 'X',
      'targetParentId': 'P',
    }, subject: const SyncEntityRef.deck('X'));

    expect(await store.pendingEntities(), {
      const SyncEntityRef.card('k1'),
      const SyncEntityRef.deck('X'),
    });
  });

  test('entries leave in seq order and one at a time', () async {
    final outbox = SyncOutboxWriter(db);
    await outbox.command(SyncCommandType.renameDeck, {
      'deckId': 'A',
      'name': 'a',
    });
    await outbox.command(SyncCommandType.renameDeck, {
      'deckId': 'B',
      'name': 'b',
    });
    final batch = await store.pendingBatch(10);
    expect(batch.map((e) => e.seq).toList(), [
      batch.first.seq,
      batch.first.seq + 1,
    ]);

    await store.remove(batch.first.opId);

    expect(await store.pendingBatch(10), hasLength(1));
  });

  test(
    'writes applied from the server leave nothing in the collector',
    () async {
      await store.applyingServer(
        () => db.customStatement(
          "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
          "scheduler_version, generation, sibling_position, created_at, updated_at) "
          "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
        ),
      );
      expect(
        await db.customSelect('SELECT * FROM sync_changed').get(),
        isEmpty,
      );
    },
  );

  test('the since cursor', () async {
    await store.setSince(42);
    expect(await store.since(), 42);
  });
}

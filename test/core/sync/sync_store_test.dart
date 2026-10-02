import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';

Future<void> _root(AppDatabase db, String id) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, id],
);

void main() {
  late AppDatabase db;
  late SyncStore store;
  setUp(() {
    db = openTestDatabase();
    store = SyncStore(db);
  });
  tearDown(() => db.close());

  test('no entity type has no pending entry', () async {
    await store.enqueue('deck', 'D', 'upsert', DateTime.utc(2026, 9, 1));

    expect(await store.pendingBatch(const [], 10), isEmpty);
  });

  test('the device id is created once and kept', () async {
    final first = await store.deviceId();
    expect(await store.deviceId(), first);
  });

  test(
    'an acknowledgement removes the entry only while its op id is current',
    () async {
      await _root(db, 'R');
      final sent = (await store.pendingBatch(['deck'], 10)).single.opId;
      await db.customStatement(
        "UPDATE deck SET name = 'edited' WHERE id = 'R'",
      );

      await store.removeIfUnchanged(sent);

      expect(await store.pendingBatch(['deck'], 10), hasLength(1));
    },
  );

  test('a pending entity and the since cursor', () async {
    await _root(db, 'R');
    await store.setSince(42);

    expect(await store.isPendingEntity('deck', 'R'), isTrue);
    expect(await store.isPendingEntity('deck', 'S'), isFalse);
    expect(await store.since(), 42);
  });

  final t0 = DateTime.utc(2026, 9, 28, 10);

  test('a later success hides the failure; a later failure shows', () async {
    await store.recordFailure(SyncFailureKind.network, t0);
    var status = await store.watchStatus().first;
    expect(status.lastFailure?.kind, SyncFailureKind.network);

    await store.recordSuccess(t0.add(const Duration(milliseconds: 1)));
    status = await store.watchStatus().first;
    expect(status.lastFailure, isNull);
    expect(status.lastSuccessAt, t0.add(const Duration(milliseconds: 1)));

    await store.recordFailure(
      SyncFailureKind.server,
      t0.add(const Duration(milliseconds: 2)),
    );
    status = await store.watchStatus().first;
    expect(status.lastFailure?.kind, SyncFailureKind.server);
  });

  test('pending changes and their oldest time are counted', () async {
    await _root(db, 'R');
    await _root(db, 'S');
    final status = await store.watchStatus().first;
    expect(status.pendingCount, 2);
    expect(status.oldestPendingAt, isNotNull);
  });

  test('a rejection is recorded, replaced, cleared and forgotten', () async {
    await store.recordRejection('deck', 'R', 'VALIDATION_FAILED', t0);
    await store.recordRejection('deck', 'R', 'DECK_PARENT_MISSING', t0);
    await store.recordRejection('deck', 'S', 'VALIDATION_FAILED', t0);
    expect((await store.rejections()).map((r) => '${r.entityId}:${r.code}'), [
      'R:DECK_PARENT_MISSING',
      'S:VALIDATION_FAILED',
    ]);
    expect((await store.watchStatus().first).rejectedCount, 2);

    await store.clearRejection('deck', 'R');
    expect(await store.rejections(), hasLength(1));

    await store.forgetRejected();
    expect(await store.rejections(), isEmpty);
  });

  test(
    'enqueue adds an entry, or replaces the op id and keeps the time',
    () async {
      await _root(db, 'R');
      final before = (await store.pendingBatch(['deck'], 10)).single;

      await store.enqueue('deck', 'R', 'delete', t0);
      await store.enqueue('deck', 'X', 'upsert', t0);

      final after = await store.pendingBatch(['deck'], 10);
      final r = after.firstWhere((e) => e.entityId == 'R');
      expect(r.op, 'delete');
      expect(r.opId, isNot(before.opId));
      expect(r.createdAt, before.createdAt);
      expect(after.map((e) => e.entityId), containsAll(['R', 'X']));
    },
  );

  test('the status stream emits on each change', () async {
    final seen = <int>[];
    final sub = store.watchStatus().listen((s) => seen.add(s.rejectedCount));
    await pumpEventQueue();
    await store.recordRejection('deck', 'R', 'VALIDATION_FAILED', t0);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [0, 1]);
  });

  test('markAllPending queues every row parents first, once, and rewinds the cursor', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = SyncStore(db);
    await store.applyingRemote(() async {
      for (final sql in [
        "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('b', 'deck', 'x', 0)",
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('C', 'c', 'R', 'R', 2, 'card', 0, 0, 0)",
        "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('K', 'C', 'f', 'b', 0, 0)",
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
        "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, answer_count, lapse_count, current_box) VALUES ('K', 'eight_box', 1, 1, 1, 0, 1)",
        "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, \"action\", answered_at) VALUES ('V', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
      ]) {
        await db.customStatement(sql);
      }
    });
    await store.setSince(42);
    await store.enqueue('deck', 'R', 'delete', DateTime.utc(2026));

    await store.markAllPending();
    await store.markAllPending();

    final queued = await db
        .customSelect(
          'SELECT entity_type, entity_id, op FROM sync_outbox ORDER BY rowid',
        )
        .get();
    expect(
      [
        for (final row in queued)
          '${row.read<String>('entity_type')}:${row.read<String>('entity_id')}:${row.read<String>('op')}',
      ],
      [
        'deck:R:delete',
        'delete_batch:b:upsert',
        'deck:C:upsert',
        'tag:t:upsert',
        'card:K:upsert',
        'card_schedule:K:upsert',
        'review_log:V:upsert',
        'account_settings:00000000-0000-0000-0000-000000000000:upsert',
      ],
    );
    expect(await store.since(), 0);
    expect(await store.pendingCount(), 8);
  });
}

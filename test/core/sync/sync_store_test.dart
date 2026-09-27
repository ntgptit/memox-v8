import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
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

  test('the device id is created once and kept', () async {
    final first = await store.deviceId();
    expect(await store.deviceId(), first);
  });

  test(
    'an acknowledgement removes the entry only while its op id is current',
    () async {
      await _root(db, 'R');
      final sent = (await store.pendingBatch({'deck'}, 10)).single.opId;
      await db.customStatement(
        "UPDATE deck SET name = 'edited' WHERE id = 'R'",
      );

      await store.removeIfUnchanged(sent);

      expect(await store.pendingBatch({'deck'}, 10), hasLength(1));
    },
  );

  test('pending keys and the since cursor', () async {
    await _root(db, 'R');
    await store.setSince(42);

    expect(await store.pendingKeys(), {'deck/R'});
    expect(await store.since(), 42);
  });
}

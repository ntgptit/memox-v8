import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/purge_trash_use_case.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

// BR-TRASH-009 (R10): the purge clock's server time is read from the sync
// state. A stored value that cannot be read leaves the use cases as a
// Failure, which the screen and the dialog already handle, never as a raw
// error.
void main() {
  late AppDatabase db;
  late PurgeExpiredTrashUseCase auto;
  late PurgeTrashUseCase manual;

  setUp(() {
    db = openTestDatabase();
    final clock = FakeDayClock(DateTime(2026, 10, 3, 9));
    final trash = TrashRepositoryImpl(db);
    auto = PurgeExpiredTrashUseCase(trash, clock, SyncStore(db).serverTime);
    manual = PurgeTrashUseCase(trash, clock, SyncStore(db).serverTime);
  });
  tearDown(() => db.close());

  // 9e15 ms parses as a number but is past the last instant DateTime holds.
  Future<void> store(String value) => db.customStatement(
    "INSERT OR REPLACE INTO sync_state (name, value) VALUES ('server_time', ?)",
    [value],
  );

  test('a stored time out of range is a Failure from both purges', () async {
    await store('9000000000000000');

    await expectLater(auto(), throwsA(isA<Failure>()));
    await expectLater(manual(batchIds: {'b'}), throwsA(isA<Failure>()));
  });

  test('a stored time that is not a number reads as never synced', () async {
    await store('not a number');

    expect((await auto()).purged, isEmpty);
    expect((await manual(batchIds: {'b'})).purged, isEmpty);
  });

  test('a corrupt stored time is replaced by the next sync', () async {
    await store('9000000000000000');
    final seen = DateTime.utc(2026, 10, 3, 8);

    await SyncStore(db).recordServerTime(seen);

    expect(await SyncStore(db).serverTime(), seen);
  });
}

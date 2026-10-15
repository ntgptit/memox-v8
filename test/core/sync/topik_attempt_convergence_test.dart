import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/topik/data/datasources/topik_attempt_sync_dao.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';

import '../../support/test_database.dart';
import '../../support/topik_attempt_fixtures.dart';
import '../../support/topik_content_fixtures.dart';
import 'fake_sync_server.dart';

/// TOPIK spec §7.2, BR-TOPIK-026: a submitted attempt reaches every device of
/// the account; one in progress stays on its device; a delete is final.
class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    coordinator = SyncCoordinator(
      api: server,
      store: SyncStore(db),
      adapters: [TopikAttemptSyncDao(db)],
    );
    attempts = TopikAttemptRepositoryImpl(db);
  }
  final AppDatabase db;
  late final SyncCoordinator coordinator;
  late final TopikAttemptRepositoryImpl attempts;
}

void main() {
  final content = topikTestFixture();
  late FakeSyncServer server;
  late _Device a;
  late _Device b;

  Future<void> run(List<_Device> order) async {
    for (final device in order) {
      await device.coordinator.runOnce();
    }
  }

  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test(
    'a submitted attempt reaches the other device with its answers',
    () async {
      final attempt = topikOk(await a.attempts.start(content));
      topikOk(
        await a.attempts.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 1,
          elapsedMs: 800,
        ),
      );
      topikOk(
        await a.attempts.submit(
          attemptId: attempt.id,
          test: content,
          elapsedMs: 0,
        ),
      );

      await run([a, b]);

      final copy = (await topikAttemptRow(b.db, attempt.id))!;
      expect(copy.status, 'completed');
      expect(copy.score, 2);
      expect(copy.serverVersion, isNotNull);
      expect(await topikAnswerRows(b.db, attempt.id), hasLength(50));
      expect(
        (await topikAttemptRow(a.db, attempt.id))!.serverVersion,
        isNotNull,
      );
      expect(await a.db.select(a.db.syncOutbox).get(), isEmpty);
    },
  );

  test('an attempt in progress never leaves its device', () async {
    final attempt = topikOk(await a.attempts.start(content));

    await run([a, b]);

    expect(await topikAttemptRow(b.db, attempt.id), isNull);
    expect(server.row('topik_attempt', attempt.id), isNull);
  });

  test('deleting a submitted attempt removes it everywhere', () async {
    final attempt = topikOk(await a.attempts.start(content));
    topikOk(
      await a.attempts.submit(
        attemptId: attempt.id,
        test: content,
        elapsedMs: 0,
      ),
    );
    await run([a, b]);

    topikOk(await a.attempts.delete(attempt.id));
    await run([a, b]);

    expect(await topikAttemptRow(b.db, attempt.id), isNull);
    expect(await topikAnswerRows(b.db, attempt.id), isEmpty);
  });
}

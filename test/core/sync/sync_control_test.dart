import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_sync_dao.dart';
import 'package:memox/features/trash/data/datasources/delete_batch_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/review_log_sync_dao.dart';
import 'package:memox/core/sync/sync_control.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_models.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/tags/data/datasources/tag_sync_dao.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

void main() {
  test('push all empties the outbox; pull all reads from version 0', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = SyncStore(db);
    final server = FakeSyncServer();
    final coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [
        DeleteBatchSyncDao(db),
        DeckSyncDao(db),
        TagSyncDao(db, store),
        CardSyncDao(db),
        CardScheduleSyncDao(db, store),
        ReviewLogSyncDao(db),
        AccountSettingsSyncDao(db),
      ],
    );
    final control = AppSyncControl(
      scheduler: null,
      coordinator: coordinator,
      store: store,
    );
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
    );
    expect(await control.pendingCount(), 1);

    await control.pushPending();
    expect(await control.pendingCount(), 0);
    expect(server.row('tag', 't'), isNotNull);

    await store.setSince(99);
    await control.pullAll();
    expect(await store.since(), greaterThan(0));
  });

  test('a push that never reached the server is an OfflineFailure', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = SyncStore(db);
    final control = AppSyncControl(
      scheduler: null,
      coordinator: SyncCoordinator(
        api: _OfflineApi(),
        store: store,
        adapters: [TagSyncDao(db, store)],
      ),
      store: store,
    );
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
    );

    await expectLater(control.pushPending(), throwsA(isA<OfflineFailure>()));
  });

  test(
    'I2: a row the server refused is still unsent; pushing all says so',
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);
      final store = SyncStore(db);
      final server = FakeSyncServer()
        ..rejectNext['tag/t'] = 'VALIDATION_FAILED';
      final control = AppSyncControl(
        scheduler: null,
        coordinator: SyncCoordinator(
          api: server,
          store: store,
          adapters: [TagSyncDao(db, store)],
        ),
        store: store,
      );
      await db.customStatement(
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
      );

      await expectLater(
        control.pushPending(),
        throwsA(isA<UnsentChangesFailure>().having((f) => f.count, 'count', 1)),
      );
      expect(await control.pendingCount(), 1);
    },
  );
}

class _OfflineApi extends FakeSyncServer {
  @override
  Future<PushResponseModel> push(PushRequestModel request) async =>
      throw const SocketException('down');
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_sync_dao.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/review_log_sync_dao.dart';
import 'package:memox/features/tags/data/datasources/tag_sync_dao.dart';
import 'package:memox/features/trash/data/datasources/delete_batch_sync_dao.dart';

import '../../support/recording_log_sink.dart';
import '../../support/test_database.dart';
import 'fake_sync_server.dart';

// How the pull half of a run applies what the server sends (sync library
// spec §4.2, app deck-sync spec §5):
// - DEV-206: a page is applied as it arrives, inside the one transaction,
//   so the pull never holds more than one page;
// - DEV-210: `afterPull` runs only when the pull applied something;
// - DEV-185: a change this device cannot hold fails alone, listed as
//   PULL_APPLY_FAILED, and the cursor still moves; a commit that fails on a
//   deferred key names the rows.

/// Records what reaches it and applies nothing (an adapter of type [entityType]).
final class _RecordingAdapter extends EntitySyncAdapter {
  _RecordingAdapter(this.entityType);

  @override
  final String entityType;
  final applied = <String>[];
  var afterPullCalls = 0;

  @override
  Future<Map<String, Object?>?> readRow(String id) async => null;

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int version) async =>
      applied.add(id(row));

  @override
  Future<void> deleteFromServer(String id) async => applied.add(id);

  @override
  Future<void> markAcknowledged(String id, int version) async {}

  @override
  Future<void> afterPull() async => afterPullCalls++;

  static String id(Map<String, Object?> row) => row['id'] as String;
}

class _Device {
  _Device(
    FakeSyncServer server, {
    int pullLimit = SyncCoordinator.pullPageSize,
    List<EntitySyncAdapter> Function(AppDatabase db)? adapters,
    AppLogger? logger,
  }) : db = openTestDatabase() {
    final store = SyncStore(db);
    coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters:
          adapters?.call(db) ??
          [
            DeleteBatchSyncDao(db),
            DeckSyncDao(db),
            TagSyncDao(db, store),
            CardSyncDao(db),
            CardScheduleSyncDao(db, store),
            ReviewLogSyncDao(db),
            AccountSettingsSyncDao(db),
          ],
      pullLimit: pullLimit,
      logger: logger,
    );
  }

  final AppDatabase db;
  late final SyncCoordinator coordinator;

  Future<List<SyncRejectionEntry>> rejections() =>
      db.select(db.syncRejection).get();

  Future<int> since() => SyncStore(db).since();

  Future<bool> hasDeck(String id) async => (await (db.select(
    db.deck,
  )..where((d) => d.id.equals(id))).get()).isNotEmpty;
}

Map<String, Object?> _rootRow(String id, {int depth = 1}) => {
  'id': id,
  'name': id,
  'parentId': null,
  'rootId': id,
  'depth': depth,
  'contentType': 'deck',
  'schedulerType': 'sm2',
  'schedulerVersion': 1,
  'schedulerConfig': null,
  'studyConfig': null,
  'generation': 1,
  'firstAnsweredAt': null,
  'sourceTemplateId': null,
  'sourceTemplateVersion': null,
  'deleteBatchId': null,
  'siblingPosition': 0,
  'createdAt': '2026-09-28T00:00:00Z',
  'updatedAt': '2026-09-28T00:00:00Z',
};

Map<String, Object?> _childRow(String id, String parent) => {
  ..._rootRow(id),
  'parentId': parent,
  'rootId': parent,
  'depth': 2,
  'contentType': 'unset',
  'schedulerType': null,
  'schedulerVersion': null,
  'generation': null,
};

void main() {
  late FakeSyncServer server;
  setUp(() => server = FakeSyncServer());

  group('a page is applied as it arrives (DEV-206)', () {
    test('the next page is asked for only once the previous one is applied, '
        'and nothing is kept across pages', () async {
      final adapter = _RecordingAdapter('a');
      server
        ..seed('a', '1', {'id': '1'})
        ..seed('a', '2', {'id': '2'})
        ..seed('a', '3', {'id': '3'});
      final device = _Device(server, pullLimit: 2, adapters: (_) => [adapter]);
      addTearDown(device.db.close);
      final appliedWhenAsked = <int, List<String>>{};
      server.beforeChanges = (since) async {
        appliedWhenAsked[since] = List.of(adapter.applied);
      };

      await device.coordinator.runOnce();

      expect(appliedWhenAsked, {
        0: <String>[],
        2: ['1', '2'],
      });
      expect(adapter.applied, ['1', '2', '3']);
      expect(await device.since(), 3);
    });

    test('a child on an earlier page than its parent still applies, and a '
        'failed page keeps nothing', () async {
      server
        ..seed('deck', 'C', _childRow('C', 'R'))
        ..seed('deck', 'R', _rootRow('R'))
        ..seed('deck', 'R2', _rootRow('R2'));
      final device = _Device(server, pullLimit: 1);
      addTearDown(device.db.close);

      await device.coordinator.runOnce();

      expect(await device.hasDeck('C'), isTrue);
      expect(await device.hasDeck('R2'), isTrue);
      expect(await device.since(), 3);

      server
        ..seed('deck', 'R3', _rootRow('R3'))
        ..seed('deck', 'R4', _rootRow('R4'))
        ..failChangesAfter = 4;
      await expectLater(device.coordinator.runOnce(), throwsStateError);
      expect(await device.hasDeck('R3'), isFalse);
      expect(await device.since(), 3);
    });
  });

  group('afterPull (DEV-210)', () {
    test('does not run when the pull brought nothing', () async {
      final adapter = _RecordingAdapter('a');
      final device = _Device(server, adapters: (_) => [adapter]);
      addTearDown(device.db.close);

      await device.coordinator.runOnce();
      await device.coordinator.runOnce();

      expect(adapter.afterPullCalls, 0);
    });

    test(
      'runs once, on every adapter, when the pull applied a change',
      () async {
        final a = _RecordingAdapter('a');
        final b = _RecordingAdapter('b');
        server.seed('a', '1', {'id': '1'});
        final device = _Device(server, pullLimit: 1, adapters: (_) => [a, b]);
        addTearDown(device.db.close);

        await device.coordinator.runOnce();

        expect(a.afterPullCalls, 1);
        expect(b.afterPullCalls, 1, reason: 'a type with no change too');
      },
    );
  });

  group('a change this device cannot hold (DEV-185)', () {
    test('fails alone: the others apply, since moves, and it is listed as '
        'PULL_APPLY_FAILED until a copy applies', () async {
      server
        ..seed('deck', 'R', _rootRow('R'))
        ..seed('deck', 'Bad', _rootRow('Bad', depth: 11))
        ..seed('deck', 'R2', _rootRow('R2'));
      final device = _Device(server);
      addTearDown(device.db.close);

      await device.coordinator.runOnce();

      expect(await device.hasDeck('R'), isTrue);
      expect(await device.hasDeck('R2'), isTrue);
      expect(await device.hasDeck('Bad'), isFalse);
      expect(await device.since(), 3);
      final listed = (await device.rejections()).single;
      expect((listed.entityType, listed.entityId), ('deck', 'Bad'));
      expect(listed.code, SyncCoordinator.pullApplyFailed);

      // Try again pushes nothing for it: there is no local row to send.
      await device.coordinator.requeueRejected();
      expect(await device.db.select(device.db.syncOutbox).get(), isEmpty);

      // The server fixes the row: the next pull applies it and clears it.
      server.seed('deck', 'Bad', _rootRow('Bad'));
      await device.coordinator.runOnce();
      expect(await device.hasDeck('Bad'), isTrue);
      expect(await device.rejections(), isEmpty);
    });

    test('a commit that fails on a deferred key names the rows and keeps '
        'nothing', () async {
      final sink = RecordingLogSink();
      server
        ..seed('deck', 'R', _rootRow('R'))
        ..seed('deck', 'Orphan', _childRow('Orphan', 'Missing'));
      final device = _Device(server, logger: AppLogger(sinks: [sink]));
      addTearDown(device.db.close);

      await expectLater(device.coordinator.runOnce(), throwsA(anything));

      expect(await device.hasDeck('R'), isFalse);
      expect(await device.since(), 0);
      final entry = sink.entries.singleWhere(
        (e) => e.event == 'sync.pull_foreign_keys',
      );
      expect(entry.context['violations'].toString(), contains('deck'));
    });
  });
}

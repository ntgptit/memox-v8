import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/account_settings_sync_adapter.dart';
import 'package:memox/core/sync/card_schedule_sync_adapter.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/review_log_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

/// SB-S4: reviews and schedules converge across two devices (library and
/// study sync spec §3.3–3.4, ADR-017).
class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    final store = SyncStore(db);
    final cards = CardSyncAdapter(db);
    coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [
        DeleteBatchSyncAdapter(db),
        DeckSyncAdapter(db),
        TagSyncAdapter(db, store),
        cards,
        CardScheduleSyncAdapter(db, store),
        ReviewLogSyncAdapter(db),
        AccountSettingsSyncAdapter(db),
      ],
    );
  }
  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

// 2026-09-28 10:00, 11:00 and 12:00 UTC, as Drift stores them (seconds).
const _ten = 1790589600;
const _eleven = 1790593200;
const _noon = 1790596800;

Future<void> _answer(AppDatabase db, int at, {int generation = 1}) =>
    db.customStatement(
      'UPDATE card_schedule SET last_answered_at = ?, answer_count = answer_count + 1, '
      "generation = ? WHERE card_id = 'K'",
      [at, generation],
    );

Future<void> _review(
  AppDatabase db,
  String id,
  int at, {
  int generation = 1,
}) => db.customStatement(
  'INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, '
  "\"action\", answered_at) VALUES (?, 'K', 's', 'eight_box', ?, 'learning', "
  "'self_assess', 'remembered', ?)",
  [id, generation, at],
);

Future<CardSchedule> _schedule(AppDatabase db) => (db.select(
  db.cardSchedule,
)..where((s) => s.cardId.equals('K'))).getSingle();

Future<Set<String>> _reviews(AppDatabase db) async => {
  for (final r in await db.select(db.reviewLog).get()) r.id,
};

void main() {
  late FakeSyncServer server;
  late _Device a;
  late _Device b;

  Future<void> run(List<_Device> order) async {
    for (final device in order) {
      await device.coordinator.runOnce();
    }
  }

  setUp(() async {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
    await a.db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
    );
    await a.db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES ('K', 'R', 'f', 'b', 0, 0)",
    );
    await a.db.customStatement(
      "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, "
      "answer_count, lapse_count, current_box) VALUES ('K', 'eight_box', 1, 1, 0, 0, 1)",
    );
    await run([a, b]);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test(
    'two devices answering offline keep the later answer and both reviews',
    () async {
      await _answer(a.db, _ten);
      await _review(a.db, 'VA', _ten);
      await _answer(b.db, _eleven);
      await _review(b.db, 'VB', _eleven);

      await run([a, b, a, b]);

      for (final device in [a, b]) {
        final schedule = await _schedule(device.db);
        expect(
          schedule.lastAnsweredAt?.toUtc(),
          DateTime.fromMillisecondsSinceEpoch(_eleven * 1000, isUtc: true),
        );
        expect(await _reviews(device.db), {'VA', 'VB'});
        expect(await device.db.select(device.db.syncOutbox).get(), isEmpty);
      }
    },
  );

  test('the rule decides, not the order the pushes reach the server', () async {
    await _answer(a.db, _ten);
    await _answer(b.db, _eleven);

    // A's older schedule lands last on the server; B keeps its own and pushes
    // it again on its next run, and A takes it on the run after (spec §3.4:
    // at most one more push).
    await run([b, a, b, a, b, a]);

    for (final device in [a, b]) {
      expect(
        (await _schedule(device.db)).lastAnsweredAt?.toUtc(),
        DateTime.fromMillisecondsSinceEpoch(_eleven * 1000, isUtc: true),
      );
      expect(await device.db.select(device.db.syncOutbox).get(), isEmpty);
    }
  });

  test(
    'a reset beats later answers of the old generation, whose reviews stay',
    () async {
      await a.db.customStatement(
        "UPDATE deck SET generation = 2 WHERE id = 'R'",
      );
      await a.db.customStatement(
        'UPDATE card_schedule SET generation = 2, last_answered_at = NULL, answer_count = 0, '
        "learned_at = NULL, due_at = NULL WHERE card_id = 'K'",
      );
      await _answer(b.db, _noon);
      await _review(b.db, 'VB2', _noon);

      await run([a, b, a, b, a, b]);

      for (final device in [a, b]) {
        final schedule = await _schedule(device.db);
        expect(schedule.generation, 2);
        expect(schedule.lastAnsweredAt?.toUtc(), isNull);
        expect(await _reviews(device.db), {'VB2'});
      }
    },
  );
}

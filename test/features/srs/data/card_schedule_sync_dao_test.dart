import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';

import '../../../support/test_database.dart';

Future<void> _root(
  AppDatabase db,
  String id,
  String scheduler,
) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', ?, 1, 3, 0, 0, 0)",
  [id, id, scheduler],
);

Future<void> _child(AppDatabase db, String id, String parent) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) VALUES (?, 'c', ?, ?, 2, 'card', 0, 0, 0)",
      [id, parent, parent],
    );

Map<String, Object?> _wire(String id, String deckId) => {
  'id': id,
  'deckId': deckId,
  'front': 'f',
  'back': 'b',
  'isFlagged': false,
  'example': null,
  'hint': null,
  'pronunciation': null,
  'deleteBatchId': null,
  'createdAt': '2026-09-28T01:02:03Z',
  'updatedAt': '2026-09-28T01:02:04Z',
  'tagIds': <String>[],
};

void main() {
  // BR-CARD-004: a pulled card gets the schedule a new card starts with, the
  // one srs writes; one owner since DEV-173.
  for (final scheduler in ['eight_box', 'sm2']) {
    test('afterPull writes what initializeCard writes ($scheduler)', () async {
      final db = openTestDatabase();
      addTearDown(db.close);
      final cards = CardSyncDao(db);
      final schedules = CardScheduleSyncDao(db, SyncStore(db));
      await _root(db, 'R', scheduler);
      await _child(db, 'D', 'R');
      await cards.upsertFromServer(_wire('pulled', 'D'), 1);
      await cards.upsertFromServer(_wire('local', 'D'), 2);
      await ScheduleRepositoryImpl(db).initializeCard(cardId: 'local');

      await schedules.afterPull();
      await schedules.afterPull();

      final rows = await db.select(db.cardSchedule).get();
      expect(rows, hasLength(2), reason: 'one row per card, run twice');
      Map<String, Object?> columns(CardSchedule s) =>
          s.toJson()..remove('card_id');
      expect(
        columns(rows.firstWhere((s) => s.cardId == 'pulled')),
        columns(rows.firstWhere((s) => s.cardId == 'local')),
      );
    });
  }

  // Invariant 9 (BR-SRS-028, BR-SRS-029): a pull that moved the root on,
  // past a schedule the pull had to skip because it was pending here, leaves
  // no schedule behind its root (DEV-224).
  test('afterPull reseeds a schedule whose generation or scheduler is not its '
      "root's and queues it; one at the root's is left as it is", () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = SyncStore(db);
    final cards = CardSyncDao(db);
    final schedules = CardScheduleSyncDao(db, store);
    await _root(db, 'R', 'sm2');
    await _child(db, 'D', 'R');
    await cards.upsertFromServer(_wire('behind', 'D'), 1);
    await cards.upsertFromServer(_wire('other', 'D'), 2);
    await cards.upsertFromServer(_wire('kept', 'D'), 3);
    final repository = ScheduleRepositoryImpl(db);
    for (final id in ['behind', 'other', 'kept']) {
      await repository.initializeCard(cardId: id);
    }
    await db.customStatement(
      "UPDATE card_schedule SET generation = 2, answer_count = 4 WHERE card_id = 'behind'",
    );
    await db.customStatement(
      "UPDATE card_schedule SET scheduler_type = 'eight_box', current_box = 1, "
      'ease_factor = NULL, interval_days = NULL, repetitions = NULL '
      "WHERE card_id = 'other'",
    );
    await db.customStatement(
      "UPDATE card_schedule SET answer_count = 2 WHERE card_id = 'kept'",
    );
    await db.customStatement('DELETE FROM sync_outbox');

    await store.applyingRemote(schedules.afterPull);

    final rows = {
      for (final s in await db.select(db.cardSchedule).get()) s.cardId: s,
    };
    expect(rows['behind']!.generation, 3);
    expect(rows['behind']!.answerCount, 0);
    expect(rows['other']!.schedulerType, 'sm2');
    expect(rows['other']!.generation, 3);
    expect(rows['kept']!.answerCount, 2);
    expect(await store.isPendingEntity('card_schedule', 'behind'), isTrue);
    expect(await store.isPendingEntity('card_schedule', 'other'), isTrue);
    expect(await store.isPendingEntity('card_schedule', 'kept'), isFalse);
  });
}

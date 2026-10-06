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
}

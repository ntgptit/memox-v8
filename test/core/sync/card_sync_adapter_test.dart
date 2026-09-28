import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';

import '../../support/test_database.dart';

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
  'front': ' Äpfel ',
  'back': 'APPLE',
  'isFlagged': true,
  'example': 'ex',
  'hint': null,
  'pronunciation': 'ap',
  'deleteBatchId': null,
  'createdAt': '2026-09-28T01:02:03Z',
  'updatedAt': '2026-09-28T01:02:04Z',
};

void main() {
  late AppDatabase db;
  late CardSyncAdapter adapter;
  setUp(() {
    db = openTestDatabase();
    adapter = CardSyncAdapter(db);
  });
  tearDown(() => db.close());

  test('a pulled card reads back as the same wire row', () async {
    await _root(db, 'R', 'sm2');
    await _child(db, 'D', 'R');

    await adapter.upsertFromServer(_wire('K', 'D'), 9);

    expect(await adapter.readRow('K'), _wire('K', 'D'));
    final row = await (db.select(
      db.card,
    )..where((c) => c.id.equals('K'))).getSingle();
    expect(row.serverVersion, 9);
    expect(row.frontFolded, 'äpfel', reason: 'folded as the repository folds');
    expect(row.backFolded, 'apple');
    expect(row.isFlagged, 1);
  });

  test('a deleted card and a missing card read as null', () async {
    await _root(db, 'R', 'sm2');
    await adapter.upsertFromServer(_wire('K', 'R'), 1);
    await adapter.deleteFromServer('K');
    expect(await adapter.readRow('K'), isNull);
    expect(await adapter.readRow('nope'), isNull);
  });

  test('markAcknowledged records the version', () async {
    await _root(db, 'R', 'sm2');
    await adapter.upsertFromServer(_wire('K', 'R'), 1);
    await adapter.markAcknowledged('K', 42);
    final row = await (db.select(
      db.card,
    )..where((c) => c.id.equals('K'))).getSingle();
    expect(row.serverVersion, 42);
  });

  for (final scheduler in ['eight_box', 'sm2']) {
    test(
      'ensureSchedules writes what initializeCard writes ($scheduler)',
      () async {
        await _root(db, 'R', scheduler);
        await _child(db, 'D', 'R');
        await adapter.upsertFromServer(_wire('pulled', 'D'), 1);
        await adapter.upsertFromServer(_wire('local', 'D'), 2);
        await ScheduleRepositoryImpl(db).initializeCard(cardId: 'local');

        await adapter.ensureSchedules();
        await adapter.ensureSchedules();

        final rows = await db.select(db.cardSchedule).get();
        expect(rows, hasLength(2), reason: 'one row per card, run twice');
        Map<String, Object?> columns(CardSchedule s) =>
            s.toJson()..remove('card_id');
        expect(
          columns(rows.firstWhere((s) => s.cardId == 'pulled')),
          columns(rows.firstWhere((s) => s.cardId == 'local')),
        );
      },
    );
  }
}

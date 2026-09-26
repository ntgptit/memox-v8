import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// FE-A6 D11b: the stored schedule a preview reads; it writes nothing.

void main() {
  late AppDatabase db;
  late DeckEntity leaf;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean', SchedulerType.sm2);
    leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
      intervalDays: 6,
    );
  });
  tearDown(() => db.close());

  test('the stored schedule of a card, with its scheduler', () async {
    final schedule = await ScheduleRepositoryImpl(db).scheduleOf(cardId: 'c1');

    expect(schedule, isNotNull);
    final (type, state) = schedule!;
    expect(type, SchedulerType.sm2);
    expect(state.intervalDays, 6);
    expect(state.learnedAt, DateTime(2026, 9, 1));
  });

  test('none for a card in the Trash or gone', () async {
    await insertCard(db, id: 't1', deckId: leaf.id, deleteBatchId: 'b1');

    expect(await ScheduleRepositoryImpl(db).scheduleOf(cardId: 't1'), isNull);
    expect(await ScheduleRepositoryImpl(db).scheduleOf(cardId: 'nope'), isNull);
  });
}

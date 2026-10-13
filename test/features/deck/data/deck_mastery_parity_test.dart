import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/mappers/card_mapper.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// BR-DECK-026, spec D7: the SQL count of mastered cards and the Dart display
// status (BR-CARD-006, BR-SRS-013) agree at every threshold, so neither side
// can move alone.

final _now = DateTime(2026, 9, 23, 10);
final _today = DateTime(2026, 9, 23);
final _learned = DateTime(2026, 5, 1);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl repo;

  setUp(() {
    db = openTestDatabase();
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
  });
  tearDown(() => db.close());

  Future<(int, int)> sqlAndDart() async {
    final [tile] = await repo
        .watchLevel(parentId: null, now: _now, startOfToday: _today)
        .first;
    final schedules = await db.select(db.cardSchedule).get();
    final mastered = schedules
        .where(
          (s) =>
              CardDisplayStatus.of(scheduleStateOf(s)) ==
              CardDisplayStatus.mastered,
        )
        .length;
    return (tile.masteredCount, mastered);
  }

  test('eight boxes: box 7 is not mastered, box 8 is, an unlearned card '
      'never is (BR-DECK-026)', () async {
    final root = await repo.root('Boxes');
    final leaf = await repo.sub(root.id, 'Leaf');
    await insertCard(db, id: 'b1', deckId: leaf.id, learnedAt: _learned);
    await insertCard(
      db,
      id: 'b7',
      deckId: leaf.id,
      learnedAt: _learned,
      box: 7,
    );
    await insertCard(
      db,
      id: 'b8',
      deckId: leaf.id,
      learnedAt: _learned,
      box: 8,
    );
    await insertCard(db, id: 'new8', deckId: leaf.id, box: 8);

    expect(await sqlAndDart(), (1, 1));
  });

  test('SM-2: 127 days is not mastered, 128 is, an unlearned card never is '
      '(BR-DECK-026)', () async {
    final root = await repo.root('Intervals', SchedulerType.sm2);
    final leaf = await repo.sub(root.id, 'Leaf');
    await insertCard(db, id: 'd1', deckId: leaf.id, learnedAt: _learned);
    await insertCard(
      db,
      id: 'd127',
      deckId: leaf.id,
      learnedAt: _learned,
      intervalDays: 127,
    );
    await insertCard(
      db,
      id: 'd128',
      deckId: leaf.id,
      learnedAt: _learned,
      intervalDays: 128,
    );
    await insertCard(db, id: 'new128', deckId: leaf.id, intervalDays: 128);

    expect(await sqlAndDart(), (1, 1));
  });
}

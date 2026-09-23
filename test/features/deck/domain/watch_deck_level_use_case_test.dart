import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_level_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
  });
  tearDown(() => db.close());

  test(
    'a new local day turns Due today into Overdue with no write (BR-STUDY-067)',
    () async {
      final root = await decks.root('Korean');
      final leaf = await decks.sub(root.id, 'Nouns');
      await insertCard(
        db,
        id: 'c',
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 20),
        dueAt: DateTime(2026, 9, 23),
        box: 2,
      );
      await insertCard(
        db,
        id: 'd',
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 20),
        dueAt: DateTime(2026, 9, 24),
        box: 2,
      );
      final clock = FakeDayClock(DateTime(2026, 9, 23, 22));
      final levels = <DeckLevel>[];
      final subscription = WatchDeckLevelUseCase(decks, clock)(
        parentId: root.id,
      ).listen(levels.add);
      await pumpEventQueue();

      clock.startDay(DateTime(2026, 9, 24));
      await pumpEventQueue();

      final [before, after] = [for (final level in levels) level.tiles.single];
      expect(
        (before.scheduleStatus, before.overdueCount, before.dueTodayCount),
        (DeckScheduleStatus.dueToday, 0, 1),
      );
      expect(
        (after.scheduleStatus, after.overdueDays),
        (DeckScheduleStatus.overdue, 1),
      );
      expect((after.overdueCount, after.dueTodayCount), (1, 1));
      await subscription.cancel();
    },
  );

  test('the sort and the filter reach the level', () async {
    final root = await decks.root('Korean');
    final quiet = await decks.sub(root.id, 'Quiet');
    final busy = await decks.sub(root.id, 'Busy');
    await insertCard(db, id: 'q', deckId: quiet.id);
    await insertCard(
      db,
      id: 'b',
      deckId: busy.id,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 22),
      box: 2,
    );

    final level =
        await WatchDeckLevelUseCase(
              decks,
              FakeDayClock(DateTime(2026, 9, 23, 9)),
            )(
              parentId: root.id,
              sort: DeckLevelSort.name,
              filter: DeckLevelFilter.due,
            )
            .first;

    expect([for (final tile in level.tiles) tile.name], ['Busy']);
    expect((level.newCount, level.overdueCount), (1, 1));
  });
}

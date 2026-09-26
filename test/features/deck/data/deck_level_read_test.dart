import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// S-DUE (agent-execution-guide §6.2) at T0 = 2026-09-23 10:00, with every
// due_at on a local midnight (BR-STUDY-074).
final _now = DateTime(2026, 9, 23, 10);
final _today = DateTime(2026, 9, 23);

void main() {
  late SelectCounter counter;
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  late DeckEntity library;
  late DeckEntity mixed;
  late DeckEntity noDueGroup;

  setUp(() async {
    counter = SelectCounter();
    db = openTestDatabase(interceptor: counter);
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    library = await repo.root('Due library');
    mixed = await repo.sub(library.id, 'Mixed due');
    noDueGroup = await repo.sub(library.id, 'No due group');
    final futureOnly = await repo.sub(noDueGroup.id, 'Future only');
    await insertCard(db, id: 'new', deckId: mixed.id);
    await insertCard(
      db,
      id: 'begin',
      deckId: mixed.id,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: _today,
      box: 2,
    );
    await insertCard(
      db,
      id: 'review',
      deckId: mixed.id,
      learnedAt: DateTime(2026, 9, 10),
      dueAt: DateTime(2026, 9, 22),
      box: 5,
    );
    await insertCard(
      db,
      id: 'master',
      deckId: mixed.id,
      learnedAt: DateTime(2026, 5, 1),
      dueAt: DateTime(2026, 10, 23),
      box: 8,
    );
    await insertCard(
      db,
      id: 'future',
      deckId: futureOnly.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 25),
      box: 4,
    );
  });
  tearDown(() => db.close());

  Stream<List<DeckTile>> level(String? parentId) =>
      repo.watchLevel(parentId: parentId, now: _now, startOfToday: _today);

  test('the root level counts each whole tree (IT-DISC-001)', () async {
    await repo.root('Empty', SchedulerType.sm2);

    final tiles = await level(null).first;

    final [dueLibrary, empty] = tiles;
    expect(dueLibrary.name, 'Due library');
    expect(dueLibrary.schedulerType, SchedulerType.eightBox);
    expect(
      (
        dueLibrary.cardCount,
        dueLibrary.newCount,
        dueLibrary.overdueCount,
        dueLibrary.dueTodayCount,
      ),
      (5, 1, 1, 1),
    );
    expect(
      (dueLibrary.subDeckCount, dueLibrary.oldestDueAt),
      (2, DateTime(2026, 9, 22)),
    );
    expect(
      (empty.cardCount, empty.schedulerType, empty.oldestDueAt),
      (0, SchedulerType.sm2, null),
    );
  });

  test(
    'a deeper level counts the subtree of each child, with the root scheduler',
    () async {
      final [mixedTile, noDueTile] = await level(library.id).first;

      expect(
        (
          mixedTile.cardCount,
          mixedTile.newCount,
          mixedTile.overdueCount,
          mixedTile.dueTodayCount,
        ),
        (4, 1, 1, 1),
      );
      expect(
        (
          noDueTile.cardCount,
          noDueTile.newCount,
          noDueTile.dueCount,
          noDueTile.subDeckCount,
        ),
        (1, 0, 0, 1),
      );
      expect(noDueTile.schedulerType, SchedulerType.eightBox);
      expect(noDueTile.startOfToday, _today);
    },
  );

  test('decks and cards in the Trash are left out (spec §8)', () async {
    await insertCard(
      db,
      id: 'trashed card',
      deckId: mixed.id,
      deleteBatchId: 'b',
    );
    await trashDeckRows(db, noDueGroup.id);
    await trashCardRow(db, 'future');

    final tiles = await level(library.id).first;

    expect(
      [for (final tile in tiles) (tile.name, tile.cardCount)],
      [('Mixed due', 4)],
    );
    final [root] = await level(null).first;
    expect((root.cardCount, root.subDeckCount), (4, 1));
  });

  test('each emission is one statement, and a new card emits again (UC-DECK-003 A2)', () async {
    counter.selects = 0;
    final emitted = <List<DeckTile>>[];
    final subscription = level(null).listen(emitted.add);
    await pumpEventQueue();
    expect((emitted.length, counter.selects), (1, 1));

    await insertCard(db, id: 'another', deckId: mixed.id);
    await pumpEventQueue();

    expect((emitted.length, counter.selects), (2, 2));
    expect(
      (emitted.last.single.cardCount, emitted.last.single.newCount),
      (6, 2),
    );
    await subscription.cancel();
  });
}

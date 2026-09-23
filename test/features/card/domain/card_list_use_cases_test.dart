import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/usecases/select_all_card_ids_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_list_use_case.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    DateTime now() => DateTime(2026, 9, 1);
    final decks = DeckRepositoryImpl(db, now: now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: now),
      TagRepositoryImpl(db, now: now),
      now: now,
    );
    final root = await decks.root('Korean');
    leaf = await decks.sub(root.id, 'Nouns');
    await insertCard(
      db,
      id: 'today',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 23),
      box: 2,
    );
    await insertCard(
      db,
      id: 'tomorrow',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 24),
      box: 2,
    );
  });
  tearDown(() => db.close());

  test(
    'a new local day brings the cards due that day into Due (BR-STUDY-068)',
    () async {
      final clock = FakeDayClock(DateTime(2026, 9, 23, 23));
      final views = <CardListView>[];
      final subscription = WatchCardListUseCase(cards, clock)(
        deckId: leaf.id,
        query: const CardListQuery(filter: CardListFilter.due),
        windowSize: 50,
      ).listen(views.add);
      await pumpEventQueue();

      clock.startDay(DateTime(2026, 9, 24));
      await pumpEventQueue();

      final [before, after] = views;
      expect({for (final item in before.items) item.id}, {'today'});
      expect({for (final item in after.items) item.id}, {'today', 'tomorrow'});
      expect((before.counts.due, after.counts.due), (1, 2));
      await subscription.cancel();
    },
  );

  test('Select all reads Due at the clock\'s now', () async {
    final select = SelectAllCardIdsUseCase(
      cards,
      FakeDayClock(DateTime(2026, 9, 24, 8)),
    );

    final ids = await select(
      deckId: leaf.id,
      query: const CardListQuery(filter: CardListFilter.due),
    );

    expect(ids, {'today', 'tomorrow'});
  });
}

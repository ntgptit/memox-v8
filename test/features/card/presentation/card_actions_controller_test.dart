import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  CardActionsController actions() =>
      container.read(cardActionsControllerProvider.notifier);

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('n');

  /// Korean › Words with cards a, b (flagged) and c; Korean › Verbs with d.
  Future<({String words, String verbs})> seed() async {
    final decks = DeckRepositoryImpl(db);
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final verbs = await decks.sub(korean.id, 'Verbs');
    await insertCard(db, id: 'a', deckId: words.id);
    await insertCard(db, id: 'b', deckId: words.id, isFlagged: true);
    await insertCard(db, id: 'c', deckId: words.id);
    await insertCard(db, id: 'd', deckId: verbs.id);
    return (words: words.id, verbs: verbs.id);
  }

  test('selectAll takes every card the query lets through', () async {
    final ids = await seed();

    expect(
      await actions().selectAll(
        deckId: ids.words,
        query: const CardListQuery(filter: CardListFilter.flagged),
      ),
      {'b'},
    );
    expect(
      await actions().selectAll(
        deckId: ids.words,
        query: const CardListQuery(),
      ),
      {'a', 'b', 'c'},
    );
  });

  test('setFlagged sets the flag on every card given', () async {
    await seed();
    await actions().setFlagged(cardIds: {'a', 'c'}, isFlagged: true);

    expect(await count('SELECT COUNT(*) AS n FROM card WHERE is_flagged'), 3);
  });

  test('addTag tags every card given', () async {
    await seed();
    final outcome = await actions().addTag(
      cardIds: {'a', 'b'},
      tagName: 'verbs',
    );

    expect(outcome, isA<Ok<Object?, TagRejection>>());
    expect(await count('SELECT COUNT(*) AS n FROM card_tags'), 2);
  });

  test('moveCards puts the cards in the target deck', () async {
    final ids = await seed();
    await actions().moveCards(cardIds: {'a', 'b'}, targetDeckId: ids.verbs);

    expect(
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?',
                variables: [Variable<String>(ids.verbs)],
              )
              .getSingle())
          .read<int>('n'),
      3,
    );
  });

  test('deleteCards deletes every card given', () async {
    await seed();
    await actions().deleteCards(cardIds: {'a', 'c'});

    expect(await count('SELECT COUNT(*) AS n FROM card'), 2);
  });
}

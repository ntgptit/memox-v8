import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
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

  test(
    'deleteCards moves every card given to the Trash, a batch each',
    () async {
      await seed();
      final outcome = await actions().deleteCards(cardIds: {'a', 'c'});

      expect((outcome as Ok<List<String>, CardRejection>).value, hasLength(2));
      expect(
        await count(
          'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
        ),
        2,
      );
    },
  );

  test('createCard saves the content, the flag and the tags', () async {
    final ids = await seed();
    final outcome = await actions().createCard(
      deckId: ids.words,
      draft: const CardDraft(
        front: 'bap',
        back: 'rice',
        isFlagged: true,
        tagNames: ['food'],
      ),
    );

    expect(outcome, isA<Ok<Object?, CardRejection>>());
    expect(await count('SELECT COUNT(*) AS n FROM card WHERE is_flagged'), 2);
    expect(await count('SELECT COUNT(*) AS n FROM card_tags'), 1);
  });

  test('editCard replaces the content and the tags', () async {
    await seed();
    await actions().editCard(
      cardId: 'a',
      draft: const CardDraft(front: 'new', back: 'back', tagNames: ['x', 'y']),
    );

    expect(
      await count("SELECT COUNT(*) AS n FROM card WHERE front = 'new'"),
      1,
    );
    expect(await count('SELECT COUNT(*) AS n FROM card_tags'), 2);
  });

  test('editCard is refused for a card that is gone', () async {
    await seed();
    await actions().deleteCards(cardIds: {'a'});
    final outcome = await actions().editCard(
      cardId: 'a',
      draft: const CardDraft(front: 'new', back: 'back'),
    );

    expect(
      outcome,
      isA<Rejected<Object?, CardRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        CardRejection.notFound,
      ),
    );
  });
}

import 'package:drift/drift.dart' show UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-SEARCH-001 A1, A3: pages across the two groups, what a write changes,
// and what one emission reads (Search spec §5.4, §6.3, §6.4).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late TagRepositoryImpl tags;
  late CardRepositoryImpl cards;
  late SearchRepositoryImpl search;
  late String koreanId;
  late String lessonId;
  final now = DateTime(2026, 9, 25, 9);

  Future<void> open([SelectCounter? counter]) async {
    db = openTestDatabase(interceptor: counter);
    decks = DeckRepositoryImpl(db, now: () => now);
    tags = TagRepositoryImpl(db, now: () => now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => now),
      tags,
      now: () => now,
    );
    search = SearchRepositoryImpl(db);
    koreanId = (await decks.root('Korean')).id;
    lessonId = (await decks.sub(koreanId, 'Lesson')).id;
  }

  setUp(open);
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<LibrarySearchResults> read(String term, {SearchCursor? through}) =>
      search.watchSearch(foldedTerm: term, through: through).first;

  List<String> ids(LibrarySearchResults results) => [
    for (final hit in results.cards) hit.cardId,
  ];

  /// Cards `c01` to `c[count]`, their fronts `học 01` to `học [count]`.
  Future<void> manyCards(int count) async {
    for (var n = 1; n <= count; n++) {
      final number = n.toString().padLeft(2, '0');
      await insertCard(
        db,
        id: 'c$number',
        deckId: lessonId,
        front: 'học $number',
      );
    }
  }

  test('decks first: the first page takes every deck, then fills with '
      'cards; nextThrough ends exactly one more page, and watching through '
      'it goes on with cards (BR-SEARCH-005, BR-SEARCH-007)', () async {
    for (var n = 1; n <= 3; n++) {
      await decks.sub(koreanId, 'Học $n');
    }
    await manyCards(99);

    final first = await read('học');
    final two = await read('học', through: first.nextThrough);

    expect((first.decks.length, first.cards.length), (3, 47));
    expect(first.nextThrough?.id, 'c97');
    expect((two.decks.length, two.cards.length), (3, 97));
    expect(two.nextThrough?.id, 'c99');
  });

  test('more than a page of decks: the first page is decks alone, and '
      'watching through nextThrough goes on from the last deck to the first '
      'card, skipping none (BR-SEARCH-005, BR-SEARCH-007)', () async {
    for (var n = 10; n < 65; n++) {
      await decks.sub(koreanId, 'Học $n');
    }
    await manyCards(3);

    final first = await read('học');
    final two = await read('học', through: first.nextThrough);

    expect((first.decks.length, first.cards.length), (50, 0));
    expect(two.decks.length, 55);
    expect(ids(two), ['c01', 'c02', 'c03']);
    expect(two.nextThrough, isNull);
  });

  test('a card written between two pages repeats no card and skips none; '
      'a card equal to another in tier, front and created_at falls to its '
      'id (BR-SEARCH-007)', () async {
    await manyCards(60);
    final first = await read('học');

    await insertCard(db, id: 'c00', deckId: lessonId, front: 'học 00');
    await insertCard(db, id: 'c99', deckId: lessonId, front: 'học 99');
    await insertCard(db, id: 'b30', deckId: lessonId, front: 'học 30');
    final shown = ids(await read('học', through: first.nextThrough));
    final rest = await read(
      'học',
      through: (await read('học', through: first.nextThrough)).nextThrough,
    );

    expect((shown.length, shown.toSet().length), (62, 62));
    expect(shown.first, 'c00');
    expect(shown.sublist(shown.indexOf('b30'), shown.indexOf('b30') + 2), [
      'b30',
      'c30',
    ]);
    expect(ids(rest).last, 'c99');
    expect(rest.nextThrough, isNull);
  });

  test('when every card through the cursor is gone while cards follow, the '
      'first page shows (Search spec §5.4)', () async {
    await manyCards(3);
    final throughFirst = (await read('học')).cards.first.cursor;

    expect(
      await cards.deleteCards(cardIds: {'c01'}),
      isA<Ok<void, CardRejection>>(),
    );
    final shown = await read('học', through: throughFirst);

    expect(ids(shown), ['c02', 'c03']);
    expect(shown.nextThrough, isNull);
  });

  test(
    'cards of a deck in the Trash take no place on a page: the live '
    'cards after them still fill it (BR-SEARCH-001, BR-SEARCH-007)',
    () async {
      final gone = await decks.sub(koreanId, 'Gone');
      for (var n = 1; n <= searchPageSize; n++) {
        await insertCard(db, id: 'g$n', deckId: gone.id, front: 'học a$n');
      }
      await trashDeckRows(db, gone.id);
      await insertCard(db, id: 'kept', deckId: lessonId, front: 'học b');

      expect(ids(await read('học')), ['kept']);
    },
  );

  test(
    'the results come again on a moved card, a deleted card, a tag put '
    'on a card and a renamed tag (BR-SEARCH-008; UC-SEARCH-001 A3)',
    () async {
      await insertCard(db, id: 'c1', deckId: lessonId, front: 'học 1');
      await insertCard(db, id: 'c2', deckId: lessonId, front: 'học 2');
      await insertCard(db, id: 'c3', deckId: lessonId, front: 'three');
      final other = await decks.sub(koreanId, 'Other');
      final shown = <LibrarySearchResults>[];
      final subscription = search
          .watchSearch(foldedTerm: 'học')
          .listen(shown.add);
      await pumpEventQueue();

      expect(
        await cards.moveCards(cardIds: {'c1'}, targetDeckId: other.id),
        isA<Ok<void, CardRejection>>(),
      );
      await pumpEventQueue();
      expect(
        [for (final step in shown.last.cards.first.deckPath) step.name],
        ['Korean', 'Other'],
      );

      expect(
        await cards.deleteCards(cardIds: {'c2'}),
        isA<Ok<void, CardRejection>>(),
      );
      await pumpEventQueue();
      expect(ids(shown.last), ['c1']);

      expect(
        await tags.attachByName(cardIds: {'c3'}, name: 'Học'),
        isA<Ok<void, TagRejection>>(),
      );
      await pumpEventQueue();
      expect(ids(shown.last), ['c3', 'c1']);

      await db.customUpdate(
        "UPDATE tags SET name = 'Học phần', name_folded = 'học phần'",
        updates: {db.tags},
        updateKind: UpdateKind.update,
      );
      await pumpEventQueue();
      expect(
        [for (final hit in shown.last.cards) (hit.cardId, hit.matchedTag)],
        [('c1', null), ('c3', 'Học phần')],
      );
      await subscription.cancel();
    },
  );

  test('one emission reads the deck tree once and runs at most two card '
      'statements, however many hits (BR-SEARCH-009)', () async {
    await db.close();
    final counter = SelectCounter();
    await open(counter);
    for (var n = 1; n <= 3; n++) {
      await decks.sub(koreanId, 'Học $n');
    }
    await manyCards(99);

    counter.selects = 0;
    final first = await read('học');
    final firstReads = counter.selects;
    counter.selects = 0;
    await read('học', through: first.nextThrough);

    expect((firstReads, counter.selects), (3, 3));
  });
}

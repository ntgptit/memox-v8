import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SEARCH-001: the deck group of the library search, its pages and its
// updates (Search spec §5, §6).

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (UC-SEARCH-001 E1).
final class _FailingSelects extends QueryInterceptor {
  bool isArmed = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isArmed) {
      throw SqliteException(extendedResultCode: 10, message: 'disk I/O error');
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late SearchRepositoryImpl search;

  void open([QueryInterceptor? interceptor]) {
    db = openTestDatabase(interceptor: interceptor);
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 25, 9));
    search = SearchRepositoryImpl(db);
  }

  setUp(open);
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<LibrarySearchResults> read(String term, {SearchCursor? through}) =>
      search.watchSearch(foldedTerm: term, through: through).first;

  List<String> names(LibrarySearchResults results) => [
    for (final hit in results.decks) hit.name,
  ];

  /// Decks `Deck 01` to `Deck [count]` under [rootId].
  Future<void> manyDecks(String rootId, int count) async {
    for (var n = 1; n <= count; n++) {
      await decks.sub(rootId, 'Deck ${n.toString().padLeft(2, '0')}');
    }
  }

  test('a deck is found by its name at any level, with its ancestors as its '
      'path and what it holds (BR-SEARCH-001; UC-SEARCH-001 step 5)', () async {
    final english = await decks.root('Tiếng Anh giao tiếp hằng ngày');
    final films = await decks.sub(english.id, 'Học qua phim');
    await insertCard(db, id: 'c1', deckId: films.id);
    await decks.root('Từ vựng học thuật');

    final results = await read('học');

    expect(
      [
        for (final hit in results.decks)
          (
            hit.name,
            [for (final step in hit.path) step.name].join(' › '),
            hit.contentType,
          ),
      ],
      [
        ('Học qua phim', 'Tiếng Anh giao tiếp hằng ngày', DeckContentType.card),
        ('Từ vựng học thuật', '', DeckContentType.deck),
      ],
    );
    expect(results.cards, isEmpty);
  });

  test('a deck in the Trash and a deleted deck are never found '
      '(BR-SEARCH-001)', () async {
    final root = await decks.root('Root');
    final kept = await decks.sub(root.id, 'Học kept');
    final trashed = await decks.sub(root.id, 'Học trashed');
    final deleted = await decks.sub(root.id, 'Học deleted');
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );
    expect(
      await decks.deleteDeck(deckId: deleted.id),
      isA<Ok<void, DeckRejection>>(),
    );

    final results = await read('học');

    expect([for (final hit in results.decks) hit.deckId], [kept.id]);
  });

  test(
    'the first page holds 50 decks, and nextThrough ends the next page: '
    'watching through it shows every deck (BR-SEARCH-005, BR-SEARCH-007)',
    () async {
      final root = await decks.root('Root');
      await manyDecks(root.id, 60);

      final first = await read('deck');
      final both = await read('deck', through: first.nextThrough);

      expect((first.decks.length, names(first).last), (50, 'Deck 50'));
      expect(names(both), [
        for (var n = 1; n <= 60; n++) 'Deck ${n.toString().padLeft(2, '0')}',
      ]);
      expect(both.nextThrough, isNull);
    },
  );

  test('a deck made between two pages repeats no deck and skips none: one '
      'before the cursor shows now, one after it with the next page '
      '(BR-SEARCH-007)', () async {
    final root = await decks.root('Root');
    await manyDecks(root.id, 60);
    final first = await read('deck');

    await decks.sub(root.id, 'Deck 00');
    await decks.sub(root.id, 'Deck 99');
    final shown = await read('deck', through: first.nextThrough);
    final rest = await read('deck', through: shown.nextThrough);

    expect(names(shown).length, 61);
    expect(names(shown).toSet().length, 61);
    expect(names(shown).first, 'Deck 00');
    expect(names(rest).last, 'Deck 99');
    expect(rest.nextThrough, isNull);
  });

  test('when every deck through the cursor is gone while decks follow, the '
      'first page shows, never an empty list with more to load '
      '(Search spec §5.4)', () async {
    final root = await decks.root('Root');
    final one = await decks.sub(root.id, 'Deck 1');
    await decks.sub(root.id, 'Deck 2');
    await decks.sub(root.id, 'Deck 3');
    final throughOne = (await read('deck')).decks.first.cursor;

    expect(
      await decks.deleteDeck(deckId: one.id),
      isA<Ok<void, DeckRejection>>(),
    );
    final shown = await read('deck', through: throughOne);

    expect(names(shown), ['Deck 2', 'Deck 3']);
    expect(shown.nextThrough, isNull);
  });

  test('reading writes nothing and opens no session (BR-SEARCH-008)', () async {
    final root = await decks.root('Học');
    await insertCard(
      db,
      id: 'c1',
      deckId: (await decks.sub(root.id, 'Lesson')).id,
    );
    final before = await totalChanges(db);

    await read('học');

    expect(await totalChanges(db), before);
    final sessions = await db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });

  test('renaming an ancestor or moving a deck gives the hits shown their '
      'new path, and a deleted deck leaves them (BR-SEARCH-008)', () async {
    final english = await decks.root('Tiếng Anh');
    final other = await decks.root('Khác');
    final film = await decks.sub(english.id, 'Học qua phim');
    final talk = await decks.sub(other.id, 'Học nói');
    final shown = <LibrarySearchResults>[];
    final subscription = search
        .watchSearch(foldedTerm: 'học')
        .listen(shown.add);
    await pumpEventQueue();
    List<String> paths() => [
      for (final hit in shown.last.decks)
        [for (final step in hit.path) step.name, hit.name].join(' › '),
    ];

    expect(
      await decks.renameDeck(deckId: english.id, name: 'English'),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(paths(), ['Khác › Học nói', 'English › Học qua phim']);

    expect(
      await decks.moveDeck(deckId: film.id, newParentId: other.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(paths(), ['Khác › Học nói', 'Khác › Học qua phim']);

    expect(
      await decks.deleteDeck(deckId: talk.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(paths(), ['Khác › Học qua phim']);
    await subscription.cancel();
  });

  test(
    'a read that fails comes as a database Failure (UC-SEARCH-001 E1)',
    () async {
      await db.close();
      final failing = _FailingSelects();
      open(failing);
      await decks.root('Học');
      failing.isArmed = true;

      await expectLater(
        search.watchSearch(foldedTerm: 'học'),
        emitsError(isA<Failure>()),
      );
      failing.isArmed = false;
    },
  );
}

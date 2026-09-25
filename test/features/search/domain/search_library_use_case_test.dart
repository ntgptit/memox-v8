import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/usecases/search_library_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SEARCH-001: the use case folds the term, and a blank one reads nothing
// (BR-SEARCH-002, BR-SEARCH-003; Search spec §7).

void main() {
  late AppDatabase db;
  late SelectCounter counter;
  late SearchLibraryUseCase searchLibrary;

  setUp(() async {
    counter = SelectCounter();
    db = openTestDatabase(interceptor: counter);
    final decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 25, 9));
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Học');
    await insertCard(db, id: 'c1', deckId: lesson.id, front: 'học 1');
    await insertCard(db, id: 'c2', deckId: lesson.id, front: 'học 2');
    searchLibrary = SearchLibraryUseCase(SearchRepositoryImpl(db));
  });
  tearDown(() => db.close());

  Future<LibrarySearchResults> results(
    String term, {
    SearchCursor? through,
  }) async =>
      await searchLibrary(term: term, through: through).first
          as LibrarySearchResults;

  test('a blank or all-space term is LibrarySearchIdle and reads nothing '
      'from the database (BR-SEARCH-003)', () async {
    counter.selects = 0;

    for (final term in ['', '   ', ' \t\n ']) {
      expect(await searchLibrary(term: term).first, isA<LibrarySearchIdle>());
    }
    expect(counter.selects, 0);
  });

  test('the term is folded before it is matched: its case and the spaces '
      'around it do not matter (BR-SEARCH-002)', () async {
    final shown = await results('  HỌC  ');

    expect([for (final hit in shown.decks) hit.name], ['Học']);
    expect([for (final hit in shown.cards) hit.cardId], ['c1', 'c2']);
  });

  test('watching through a cursor shows the hits through it '
      '(UC-SEARCH-001 A1)', () async {
    final first = await results('học');

    final shown = await results('học', through: first.cards.first.cursor);

    expect([for (final hit in shown.cards) hit.cardId], ['c1']);
    expect(shown.nextThrough?.id, 'c2');
  });
}

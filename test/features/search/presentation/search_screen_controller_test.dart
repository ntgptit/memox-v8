import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/search/di/search_repository_provider.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';

// UC-SEARCH-001: debounce, pages, failures (spec D5–D8).

final class _Watch {
  _Watch(this.term, this.through) {
    controller = StreamController<LibrarySearchResults>(
      onCancel: () => isCancelled = true,
    );
  }

  final String term;
  final SearchCursor? through;
  late final StreamController<LibrarySearchResults> controller;
  var isCancelled = false;
}

/// Hands every watch a stream the test drives.
final class _FakeSearch implements SearchRepository {
  final watches = <_Watch>[];

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) {
    final watch = _Watch(foldedTerm, through);
    watches.add(watch);
    return watch.controller.stream;
  }
}

SearchCursor _cursor(SearchGroup group, String id) => SearchCursor(
  group: group,
  tier: SearchTier.exact,
  sortText: id,
  createdAt: DateTime.utc(2026, 9, 26),
  id: id,
);

SearchDeckHit _deck(String id) => SearchDeckHit(
  deckId: id,
  name: id,
  path: const [],
  contentType: DeckContentType.card,
  cursor: _cursor(SearchGroup.deck, id),
);

SearchCardHit _card(String id) => SearchCardHit(
  cardId: id,
  deckId: 'deck',
  front: id,
  back: 'back',
  deckPath: const [],
  matchedTag: null,
  cursor: _cursor(SearchGroup.card, id),
);

LibrarySearchResults _page({
  List<SearchDeckHit> decks = const [],
  List<SearchCardHit> cards = const [],
  SearchCursor? next,
}) => LibrarySearchResults(decks: decks, cards: cards, nextThrough: next);

const _failure = UnknownDatabaseFailure(cause: '/data/memox.sqlite');

/// Runs [body] in fake time over a container whose search is [_FakeSearch].
void _run(
  void Function(
    FakeAsync async,
    SearchScreenController controller,
    SearchScreenState Function() state,
    _FakeSearch search,
  )
  body,
) {
  fakeAsync((async) {
    final search = _FakeSearch();
    final container = ProviderContainer(
      overrides: [searchRepositoryProvider.overrideWithValue(search)],
    );
    final keepAlive = container.listen(
      searchScreenControllerProvider,
      (_, _) {},
    );
    body(
      async,
      container.read(searchScreenControllerProvider.notifier),
      () => container.read(searchScreenControllerProvider),
      search,
    );
    keepAlive.close();
    container.dispose();
    async.flushMicrotasks();
  });
}

void main() {
  test('it starts idle', () {
    _run((async, controller, state, search) {
      expect(state(), isA<SearchScreenIdle>());
    });
  });

  test('a term is read once, 250 ms after the last keystroke', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce - const Duration(milliseconds: 1));
      controller.search('kor');
      async.elapse(searchDebounce - const Duration(milliseconds: 1));
      expect(search.watches, isEmpty);

      async.elapse(const Duration(milliseconds: 1));

      expect(search.watches.map((watch) => watch.term), ['kor']);
      expect(search.watches.single.through, isNull);
      expect(state(), isA<SearchScreenLoading>());
      expect((state() as SearchScreenLoading).term, 'kor');
    });
  });

  test('a blank term is idle at once and cancels the pending read', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      controller.search('   ');

      expect(state(), isA<SearchScreenIdle>());
      expect(search.watches.single.isCancelled, isTrue);

      controller.search('kx');
      controller.search('');
      async.elapse(searchDebounce * 2);
      expect(search.watches, hasLength(1));
    });
  });

  test('rows are results; no rows is no results', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      search.watches.single.controller.add(_page(decks: [_deck('a')]));
      async.flushMicrotasks();

      final results = state() as SearchScreenResults;
      expect(results.term, 'ko');
      expect(results.decks.map((hit) => hit.deckId), ['a']);
      expect(results.hasMore, isFalse);
      expect(results.more, SearchMoreStatus.idle);

      search.watches.single.controller.add(_page());
      async.flushMicrotasks();
      expect(state(), isA<SearchScreenNoResults>());
    });
  });

  test("a changed term drops the old query's rows", () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      controller.search('kx');
      async.elapse(searchDebounce);

      expect(search.watches.first.isCancelled, isTrue);
      search.watches.first.controller.add(_page(decks: [_deck('old')]));
      async.flushMicrotasks();
      expect(state(), isA<SearchScreenLoading>());
      expect((state() as SearchScreenLoading).term, 'kx');
    });
  });

  test('a later emission updates the rows in place (A3)', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      final watch = search.watches.single;
      watch.controller.add(_page(decks: [_deck('a')]));
      async.flushMicrotasks();
      watch.controller.add(_page(decks: [_deck('a'), _deck('b')]));
      async.flushMicrotasks();

      expect((state() as SearchScreenResults).decks.map((hit) => hit.deckId), [
        'a',
        'b',
      ]);
      expect(search.watches, hasLength(1));
    });
  });

  test('load more keeps the rows while it reads, then shows the longer '
      'extent (A1)', () {
    _run((async, controller, state, search) {
      final next = _cursor(SearchGroup.card, 'c1');
      controller.search('ko');
      async.elapse(searchDebounce);
      search.watches.first.controller.add(
        _page(cards: [_card('c1')], next: next),
      );
      async.flushMicrotasks();
      expect((state() as SearchScreenResults).hasMore, isTrue);

      controller.loadMore();
      controller.loadMore();

      final loading = state() as SearchScreenResults;
      expect(loading.more, SearchMoreStatus.loading);
      expect(loading.cards.map((hit) => hit.cardId), ['c1']);
      expect(search.watches, hasLength(2));
      expect(search.watches.last.through, same(next));
      expect(search.watches.first.isCancelled, isTrue);

      search.watches.last.controller.add(
        _page(cards: [_card('c1'), _card('c2')]),
      );
      async.flushMicrotasks();
      final longer = state() as SearchScreenResults;
      expect(longer.cards.map((hit) => hit.cardId), ['c1', 'c2']);
      expect(longer.more, SearchMoreStatus.idle);
      expect(longer.hasMore, isFalse);
    });
  });

  test('a load-more failure keeps the rows; retry reads the same cursor '
      '(E2)', () {
    _run((async, controller, state, search) {
      final next = _cursor(SearchGroup.card, 'c1');
      controller.search('ko');
      async.elapse(searchDebounce);
      search.watches.first.controller.add(
        _page(cards: [_card('c1')], next: next),
      );
      async.flushMicrotasks();
      controller.loadMore();
      search.watches.last.controller.addError(_failure);
      async.flushMicrotasks();

      final failed = state() as SearchScreenResults;
      expect(failed.more, SearchMoreStatus.failed);
      expect(failed.cards.map((hit) => hit.cardId), ['c1']);

      controller.retry();

      expect((state() as SearchScreenResults).more, SearchMoreStatus.loading);
      expect(search.watches, hasLength(3));
      expect(search.watches.last.through, same(next));
    });
  });

  test('a first-page failure shows no rows; retry reads from the first page '
      '(E1)', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      search.watches.single.controller.addError(_failure);
      async.flushMicrotasks();

      expect(state(), isA<SearchScreenFailed>());
      expect((state() as SearchScreenFailed).term, 'ko');

      controller.retry();

      expect(state(), isA<SearchScreenLoading>());
      expect(search.watches, hasLength(2));
      expect(search.watches.last.through, isNull);
    });
  });

  test('a failed re-read of the first page, after a write, shows no stale '
      'rows (E1)', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      final watch = search.watches.single;
      watch.controller.add(_page(decks: [_deck('a')]));
      async.flushMicrotasks();
      watch.controller.addError(_failure);
      async.flushMicrotasks();

      expect(state(), isA<SearchScreenFailed>());
    });
  });

  test('leaving cancels the pending read and the watch', () {
    fakeAsync((async) {
      final search = _FakeSearch();
      final container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(search)],
      );
      final keepAlive = container.listen(
        searchScreenControllerProvider,
        (_, _) {},
      );
      final controller = container.read(
        searchScreenControllerProvider.notifier,
      );
      controller.search('ko');
      async.elapse(searchDebounce);
      controller.search('kx');
      keepAlive.close();
      container.dispose();
      async.elapse(searchDebounce * 2);

      expect(search.watches, hasLength(1));
      expect(search.watches.single.isCancelled, isTrue);
    });
  });
}

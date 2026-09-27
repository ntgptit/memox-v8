import 'dart:async';

import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/presentation/providers/search_library_use_case_provider.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_screen_controller.g.dart';

/// How long the field stays still before a term is read (BR-SEARCH-003).
const Duration searchDebounce = Duration(milliseconds: 250);

/// Screen 04's search (UC-SEARCH-001): the debounced term, the extent it
/// watches and the one subscription to it (spec D3–D8). Widgets only draw
/// its state.
@riverpod
class SearchScreenController extends _$SearchScreenController {
  Timer? _debounce;
  StreamSubscription<LibrarySearch>? _watch;
  var _term = '';

  /// The extent the current watch shows; null is the first page.
  SearchCursor? _through;

  /// Where one more page would end; null when nothing follows.
  SearchCursor? _nextThrough;

  @override
  SearchScreenState build() {
    ref.onDispose(_stop);
    return const SearchScreenIdle();
  }

  /// The field changed. A blank term is idle at once (A4); any other is
  /// read [searchDebounce] after the last change, from the first page.
  void search(String term) {
    _stop();
    _term = term;
    if (foldText(term).isEmpty) {
      state = const SearchScreenIdle();
      return;
    }
    _debounce = Timer(searchDebounce, () => _watchThrough(null));
  }

  /// One more page, keeping the rows until it arrives (A1).
  void loadMore() {
    final current = state;
    final next = _nextThrough;
    if (current is! SearchScreenResults || next == null) return;
    if (current.more == SearchMoreStatus.loading) return;
    state = current.withMore(SearchMoreStatus.loading);
    _watchThrough(next);
  }

  /// After a failure: the first page again (E1), or the same extent (E2).
  void retry() {
    switch (state) {
      case SearchScreenFailed():
        _watchThrough(null);
      case final SearchScreenResults current
          when current.more == SearchMoreStatus.failed:
        state = current.withMore(SearchMoreStatus.loading);
        _watchThrough(_through);
      case _:
        return;
    }
  }

  String get _shownTerm => _term.trim();

  void _watchThrough(SearchCursor? through) {
    unawaited(_watch?.cancel());
    _through = through;
    if (through == null) state = SearchScreenLoading(term: _shownTerm);
    _watch = ref
        .read(searchLibraryUseCaseProvider)(term: _term, through: through)
        .listen(_show, onError: _fail);
  }

  void _show(LibrarySearch search) {
    switch (search) {
      case LibrarySearchIdle():
        state = const SearchScreenIdle();
      case LibrarySearchResults(:final decks, :final cards, :final nextThrough):
        _nextThrough = nextThrough;
        state = search.hasResults
            ? SearchScreenResults(
                term: _shownTerm,
                decks: decks,
                cards: cards,
                hasMore: nextThrough != null,
              )
            : SearchScreenNoResults(term: _shownTerm);
    }
  }

  /// A failed first page shows no rows (E1); a failed later page keeps them
  /// and turns the end of the list into a retry (E2).
  void _fail(Object error, StackTrace stackTrace) {
    final current = state;
    if (_through != null && current is SearchScreenResults) {
      state = current.withMore(SearchMoreStatus.failed);
      return;
    }
    state = SearchScreenFailed(term: _shownTerm);
  }

  void _stop() {
    _debounce?.cancel();
    _debounce = null;
    unawaited(_watch?.cancel());
    _watch = null;
  }
}

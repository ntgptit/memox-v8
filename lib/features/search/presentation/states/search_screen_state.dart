import 'package:memox/features/search/domain/models/search_hit_model.dart';

/// Where "Load more" stands (UC-SEARCH-001 A1, E2).
enum SearchMoreStatus { idle, loading, failed }

/// What screen 04 draws (UC-SEARCH-001 "UI states", spec D4). Each [term]
/// is the typed term trimmed, as the headers quote it.
sealed class SearchScreenState {
  const SearchScreenState();
}

/// No term: the hints, and nothing read (BR-SEARCH-003).
final class SearchScreenIdle extends SearchScreenState {
  const SearchScreenIdle();
}

/// The first page of [term] is being read.
final class SearchScreenLoading extends SearchScreenState {
  const SearchScreenLoading({required this.term});

  final String term;
}

/// At least one deck or card holds [term], decks first (BR-SEARCH-005).
final class SearchScreenResults extends SearchScreenState {
  const SearchScreenResults({
    required this.term,
    required this.decks,
    required this.cards,
    required this.hasMore,
    this.more = SearchMoreStatus.idle,
  });

  final String term;
  final List<SearchDeckHit> decks;
  final List<SearchCardHit> cards;

  /// Another page follows the rows shown (BR-SEARCH-007).
  final bool hasMore;
  final SearchMoreStatus more;

  SearchScreenResults withMore(SearchMoreStatus more) => SearchScreenResults(
    term: term,
    decks: decks,
    cards: cards,
    hasMore: hasMore,
    more: more,
  );
}

/// Nothing holds [term].
final class SearchScreenNoResults extends SearchScreenState {
  const SearchScreenNoResults({required this.term});

  final String term;
}

/// The first page of [term] failed; no stale row is shown (E1).
final class SearchScreenFailed extends SearchScreenState {
  const SearchScreenFailed({required this.term});

  final String term;
}

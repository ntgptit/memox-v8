import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';

/// The rows of one page (Search spec D6).
const searchPageSize = 50;

/// What the library search shows (UC-SEARCH-001).
sealed class LibrarySearch {
  const LibrarySearch();
}

/// A query that folds to empty: the initial state, and nothing was read
/// (BR-SEARCH-003).
final class LibrarySearchIdle extends LibrarySearch {
  const LibrarySearchIdle();
}

/// The hits from the first through the watched cursor, decks first
/// (BR-SEARCH-005).
final class LibrarySearchResults extends LibrarySearch {
  const LibrarySearchResults({
    required this.decks,
    required this.cards,
    required this.nextThrough,
  });

  final List<SearchDeckHit> decks;
  final List<SearchCardHit> cards;

  /// The cursor to watch through for one more page; null when nothing
  /// follows, and no "Load more" (BR-SEARCH-007; Search spec §5.4).
  final SearchCursor? nextThrough;

  bool get hasResults => decks.isNotEmpty || cards.isNotEmpty;
}

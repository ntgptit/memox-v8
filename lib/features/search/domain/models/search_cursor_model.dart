/// How a folded field holds the folded term, the best first
/// (BR-SEARCH-004).
enum SearchTier { exact, prefix, contains }

/// The tier of [folded] for [term], null when it does not hold it. Both are
/// folded with `foldText` (BR-SEARCH-002); the card statement makes the same
/// test in SQL (Search spec D4).
SearchTier? searchTierOf(String folded, String term) {
  if (folded == term) return SearchTier.exact;
  if (folded.startsWith(term)) return SearchTier.prefix;
  if (folded.contains(term)) return SearchTier.contains;
  return null;
}

/// The two groups of results, decks first (BR-SEARCH-005).
enum SearchGroup { deck, card }

/// A result's place in the total order of a search: its group, its tier,
/// the folded text it sorts on, when it was made and its id (BR-SEARCH-007).
/// The UI only hands it back.
final class SearchCursor implements Comparable<SearchCursor> {
  const SearchCursor({
    required this.group,
    required this.tier,
    required this.sortText,
    required this.createdAt,
    required this.id,
  });

  final SearchGroup group;
  final SearchTier tier;

  /// A deck's folded name, a card's `front_folded` (Search spec D5).
  final String sortText;
  final DateTime createdAt;
  final String id;

  /// Texts compare by code point, the order SQLite's BINARY collation gives
  /// UTF-8, so Dart orders the decks by the rule SQLite orders the cards by
  /// (Search spec D5).
  @override
  int compareTo(SearchCursor other) {
    final byGroup = group.index.compareTo(other.group.index);
    if (byGroup != 0) return byGroup;
    final byTier = tier.index.compareTo(other.tier.index);
    if (byTier != 0) return byTier;
    final byText = _compareCodePoints(sortText, other.sortText);
    if (byText != 0) return byText;
    final byTime = createdAt.compareTo(other.createdAt);
    if (byTime != 0) return byTime;
    return _compareCodePoints(id, other.id);
  }
}

int _compareCodePoints(String a, String b) {
  final left = a.runes.iterator;
  final right = b.runes.iterator;
  while (true) {
    final hasLeft = left.moveNext();
    final hasRight = right.moveNext();
    if (!hasLeft || !hasRight) return (hasLeft ? 1 : 0) - (hasRight ? 1 : 0);
    final byRune = left.current.compareTo(right.current);
    if (byRune != 0) return byRune;
  }
}

import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

/// A deck the search can find, as the snapshot's one read of the deck tree
/// gives it (Search spec §6.1).
final class SearchableDeck {
  const SearchableDeck({
    required this.deckId,
    required this.name,
    required this.createdAt,
    required this.path,
    required this.contentType,
  });

  final String deckId;
  final String name;
  final DateTime createdAt;

  /// The deck's ancestors, root first.
  final List<DeckPathEntry> path;
  final DeckContentType contentType;
}

/// A deck whose name holds the term (UC-SEARCH-001 step 5).
final class SearchDeckHit {
  const SearchDeckHit({
    required this.deckId,
    required this.name,
    required this.path,
    required this.contentType,
    required this.cursor,
  });

  final String deckId;

  /// The name as written; the UI emphasises the match.
  final String name;

  /// The deck's ancestors, root first, not the deck itself.
  final List<DeckPathEntry> path;
  final DeckContentType contentType;
  final SearchCursor cursor;

  SearchTier get tier => cursor.tier;
}

/// A card whose front, back or one of whose tags holds the term, once
/// however many of them do (BR-SEARCH-006; UC-SEARCH-001 step 5).
final class SearchCardHit {
  const SearchCardHit({
    required this.cardId,
    required this.deckId,
    required this.front,
    required this.back,
    required this.deckPath,
    required this.matchedTag,
    required this.cursor,
  });

  final String cardId;
  final String deckId;
  final String front;
  final String back;

  /// The card's deck with its ancestors, root first, the deck last.
  final List<DeckPathEntry> deckPath;

  /// The tag that made the card a hit, named only when neither face holds
  /// the term (Search spec D7).
  final String? matchedTag;
  final SearchCursor cursor;

  SearchTier get tier => cursor.tier;
}

/// Every deck of [decks] whose name, folded in Dart, holds [term], a folded
/// term, in the deck group's order (BR-SEARCH-001, BR-SEARCH-002,
/// BR-SEARCH-004; Search spec D3).
List<SearchDeckHit> deckHitsOf(Iterable<SearchableDeck> decks, String term) {
  final hits = [for (final deck in decks) ?_hitOf(deck, term)];
  return hits..sort((a, b) => a.cursor.compareTo(b.cursor));
}

SearchDeckHit? _hitOf(SearchableDeck deck, String term) {
  final folded = foldText(deck.name);
  final tier = searchTierOf(folded, term);
  if (tier == null) return null;
  return SearchDeckHit(
    deckId: deck.deckId,
    name: deck.name,
    path: deck.path,
    contentType: deck.contentType,
    cursor: SearchCursor(
      group: SearchGroup.deck,
      tier: tier,
      sortText: folded,
      createdAt: deck.createdAt,
      id: deck.deckId,
    ),
  );
}

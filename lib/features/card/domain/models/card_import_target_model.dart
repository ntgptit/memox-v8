import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';

/// A live direct sub-deck of an import target (spec 2026-10-08 §4.3).
final class CardImportChild {
  const CardImportChild({
    required this.id,
    required this.name,
    required this.canHoldCards,
    required this.cardCount,
    required this.pairs,
  });

  final String id;
  final String name;

  /// `unset` or a deck of cards (BR-DECK-009, BR-DECK-010).
  final bool canHoldCards;

  /// How many live cards it holds (spec 2026-10-08 C4).
  final int cardCount;

  /// The folded faces of its live cards (BR-TRANSFER-003).
  final Set<CardFoldedPair> pairs;
}

/// What an import preview knows of its target (spec 2026-10-08 §4.2).
final class CardImportTarget {
  const CardImportTarget({
    required this.isDeckOfCards,
    required this.canHoldCards,
    required this.hasRoomBelow,
    required this.pairs,
    required this.children,
  });

  /// A deck of cards (BR-DECK-009).
  final bool isDeckOfCards;

  /// `unset` or a deck of cards: a flat import writes into it.
  final bool canHoldCards;

  /// Below level 10 (BR-DECK-001).
  final bool hasRoomBelow;

  /// The folded faces of its own live cards (BR-TRANSFER-003).
  final Set<CardFoldedPair> pairs;

  /// Its live direct sub-decks, in sibling order.
  final List<CardImportChild> children;

  /// Whether a section may become a sub-deck of it (BR-TRANSFER-001).
  bool get canHoldDecks => !isDeckOfCards && hasRoomBelow;
}

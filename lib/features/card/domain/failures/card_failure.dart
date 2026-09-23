/// Why the card feature refuses a write (ADR-011 D6).
enum CardRejection {
  /// BR-CARD-001: front or back is blank.
  blankContent,

  /// BR-DECK-004, BR-DECK-009: the target deck is a root or holds sub-decks.
  notACardContainer,

  /// The target deck, or the card, no longer exists.
  notFound,
}

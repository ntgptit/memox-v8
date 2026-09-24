/// Why the card feature refuses a write (ADR-011 D6).
enum CardRejection {
  /// BR-CARD-001: front or back is blank.
  blankContent,

  /// BR-DECK-004, BR-DECK-009: the target deck is a root or holds sub-decks.
  notACardContainer,

  /// The target deck, or the card, no longer exists.
  notFound,

  /// BR-CARD-002: the front is longer than 60 characters.
  frontTooLong,

  /// BR-CARD-002: the back is longer than 240 characters.
  backTooLong,

  /// BR-CARD-003: an example, hint or pronunciation longer than 240 characters.
  optionalFieldTooLong,

  /// BR-TAG-001: a tag name the tag rule refuses.
  invalidTagName,

  /// BR-TAG-002: more than 10 distinct tags on one card.
  tooManyTags,

  /// BR-CARD-010: the move target no longer exists.
  targetNotFound,

  /// BR-CARD-010, BR-DECK-004: the move target is a root deck.
  targetIsRoot,

  /// BR-CARD-010, BR-DECK-010: the move target holds sub-decks.
  targetHoldsDecks,

  /// BR-CARD-010: a card is already in the move target.
  sameDeck,

  /// BR-CARD-010: a card and the move target belong to different roots.
  crossRootMove,
}

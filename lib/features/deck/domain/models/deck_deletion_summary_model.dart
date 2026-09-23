/// What deleting a deck takes with it, told to the person before they
/// confirm (BR-DECK-023).
final class DeckDeletionSummary {
  const DeckDeletionSummary({
    required this.subDeckCount,
    required this.cardCount,
  });

  /// Every deck below the deck, at any depth.
  final int subDeckCount;

  /// Every card in the deck and in the decks below it.
  final int cardCount;
}

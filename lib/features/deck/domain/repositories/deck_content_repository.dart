/// The one owner of a deck's content type (BR-DECK-006..008, BR-DECK-015,
/// BR-TRASH-005): what a deck holds decides it, and only the deck feature
/// writes it. A feature that adds or removes a deck's children, cards
/// included, asks for a refresh inside its own transaction and never sets
/// the column itself (DEV-215). The one implementation is
/// `DeckTreeDataSource` (data layer).
abstract interface class DeckContentRepository {
  /// Sets [deckId]'s content type to what it holds now, stamped [at] when
  /// it changes; nothing for a root (always a deck of decks, BR-DECK-004),
  /// a deck in the Trash, or one that is gone.
  Future<void> refresh(String deckId, DateTime at);
}

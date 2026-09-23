/// Why the srs feature refuses a write (ADR-011 D6).
enum SrsRejection {
  /// The action is not in the deck scheduler's `supportedActions`.
  unsupportedAction,

  /// The scheduler is locked once the first card finished learning
  /// (BR-SRS-003); only Reset learning progress unlocks it (BR-SRS-024).
  schedulerLocked,

  /// The session's generation is older than the root's (BR-SRS-026).
  staleGeneration,

  /// The card, its schedule row or the deck no longer exists.
  notFound,

  /// The deck is a sub-deck: the scheduler and the generation live on its
  /// root (BR-DECK-025).
  notARootDeck,
}

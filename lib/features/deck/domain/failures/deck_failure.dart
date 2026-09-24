/// Why the deck feature refuses a write (ADR-011 D6). Every value is a rule
/// from the spec or schema.md, checked before the database is touched.
enum DeckRejection {
  blankName,
  depthExceeded,
  notADeckContainer,
  notACardContainer,
  subtreeSchedulerMismatch,
  movingIntoOwnSubtree,
  rootCannotMove,
  notFound,

  /// BR-DECK-020: the name is longer than 200 characters.
  nameTooLong,

  /// BR-SRS-007: the deck and its anchor no longer share a parent.
  notSiblings,

  /// A move to the parent the deck already has.
  sameParent,
}

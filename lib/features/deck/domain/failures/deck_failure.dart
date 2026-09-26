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

  /// BR-TRASH-006: the deck a restore is aimed at no longer exists.
  targetNotFound,

  /// BR-TRASH-006, BR-TRASH-008: the deck a restore or an Undo is aimed at
  /// is in the Trash itself.
  targetInTrash,

  /// BR-TRASH-006: a root deck goes back to the top level only.
  rootRestoresToTopLevel,

  /// BR-TRASH-006: a sub-deck goes back under a deck only.
  subDeckNeedsParent,
}

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
}

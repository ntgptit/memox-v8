/// Why the study feature refuses an operation (ADR-011 D6).
enum StudyRejection {
  /// The deck, the session or the card is gone, or in the Trash.
  notFound,

  /// The deck and its subtree hold no card still to learn.
  nothingToLearn,

  /// The deck and its subtree hold no due card (BR-STUDY-054).
  nothingDue,

  /// The mode is not one the root's algorithm offers for a review
  /// (BR-STUDY-055).
  modeNotOffered,

  /// The mode cannot run on the cards a review would take (BR-MODE-009).
  modeUnavailable,

  /// A review that takes a direction was asked without one: a validation
  /// error (BR-MODE-018).
  directionRequired,

  /// A direction was given where none is taken: a conflict (BR-MODE-018).
  directionNotAllowed,

  /// The session has ended.
  sessionClosed,

  /// The session was opened on an earlier local day (BR-STUDY-072).
  sessionExpired,

  /// The root was reset after the session opened (BR-STUDY-017).
  staleGeneration,

  /// The answer names a card the session is not serving.
  notCurrentCard,

  /// The answer is of another mode's kind.
  answerDoesNotFitMode,

  /// The action is not in the scheduler's `supportedActions` (BR-STUDY-009).
  unsupportedAction,
}

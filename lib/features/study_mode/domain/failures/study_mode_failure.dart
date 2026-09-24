/// Why a mode refuses an answer (ADR-011 D6).
enum StudyModeRejection {
  /// The answer is of another mode's kind (spec §5.4).
  answerDoesNotFitMode,

  /// The action is not in the scheduler's `supportedActions` (BR-MODE-011,
  /// BR-STUDY-009).
  unsupportedAction,
}

/// Why a mode refuses an answer (ADR-011 D6).
enum StudyModeRejection {
  /// The answer is of another mode's kind (spec §5.4).
  answerDoesNotFitMode,

  /// The action is not in the scheduler's `supportedActions` (BR-MODE-011,
  /// BR-STUDY-009).
  unsupportedAction,

  /// `fill`: nothing is left of the answer once folded (BR-STUDY-029).
  emptyAnswer,

  /// `recall`: a self-assessment before the answer was revealed
  /// (BR-STUDY-065).
  notRevealed,

  /// `recall`: a timeout once the answer was revealed (BR-STUDY-032).
  alreadyRevealed,

  /// `guess`: the question lacks some of its five options (BR-STUDY-040).
  questionBlocked,

  /// `guess`: the chosen card is not one of the options (BR-STUDY-041).
  notAnOption,

  /// `match`: the meaning is not a pending pair of the current board
  /// (BR-STUDY-049, BR-STUDY-062).
  notOnBoard,
}

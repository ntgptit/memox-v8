import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';

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

  /// `fill`: nothing is left of the answer once folded (BR-STUDY-029).
  emptyAnswer,

  /// `recall`: a self-assessment before the answer was revealed
  /// (BR-STUDY-065).
  notRevealed,

  /// `recall`: a timeout once the answer was revealed (BR-STUDY-032).
  alreadyRevealed,

  /// `guess`: the question lacks some of its five options; the stage stops
  /// here until the person leaves (BR-STUDY-040).
  questionBlocked,

  /// `guess`: the chosen card is not one of the options (BR-STUDY-041).
  notAnOption,

  /// `match`: the meaning is not a pending pair of the current board
  /// (BR-STUDY-049, BR-STUDY-062).
  notOnBoard;

  /// A mode's refusal of an answer, as the session reports it.
  static StudyRejection ofModeRefusal(StudyModeRejection reason) =>
      switch (reason) {
        StudyModeRejection.answerDoesNotFitMode => answerDoesNotFitMode,
        StudyModeRejection.unsupportedAction => unsupportedAction,
        StudyModeRejection.emptyAnswer => emptyAnswer,
        StudyModeRejection.notRevealed => notRevealed,
        StudyModeRejection.alreadyRevealed => alreadyRevealed,
        StudyModeRejection.questionBlocked => questionBlocked,
        StudyModeRejection.notAnOption => notAnOption,
        StudyModeRejection.notOnBoard => notOnBoard,
      };

  /// srs's refusal of a turn, as the session reports it. A refusal a
  /// session never causes is a bug (spec §7.3 step 4).
  static StudyRejection ofTurnRefusal(SrsRejection reason) => switch (reason) {
    SrsRejection.notFound => notFound,
    SrsRejection.staleGeneration => staleGeneration,
    SrsRejection.unsupportedAction => unsupportedAction,
    SrsRejection.schedulerLocked || SrsRejection.notARootDeck =>
      throw StateError('srs refused a turn: $reason'),
  };
}

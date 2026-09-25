import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// A forgotten card comes back after at least this many other turns
/// (BR-STUDY-005).
const _comeBackAfterTurns = 3;

/// The turns a row may take: one first turn and three `relearning` turns
/// (BR-STUDY-073, invariant 17).
const _turnCap = 4;

/// `self_assess`: the person flips the card and grades it with one of the
/// scheduler's actions (BR-MODE-006, BR-MODE-011). No rounds: a forgotten
/// card comes back in the same queue, up to the cap (BR-STUDY-005,
/// BR-STUDY-073).
final class SelfAssessModeHandler extends StudyModeHandler {
  const SelfAssessModeHandler();

  @override
  bool get usesRounds => false;

  @override
  bool get takesDirection => true;

  @override
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  ) => switch (answer) {
    SelfAssessAnswer(:final action)
        when scheduler.supportedActions.contains(action) =>
      Ok(action),
    SelfAssessAnswer() => const Rejected(StudyModeRejection.unsupportedAction),
    AdvanceAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) => switch (answer) {
    SelfAssessAnswer(:final action)
        when scheduler.supportedActions.contains(action) =>
      Ok(TurnVerdict(action: action)),
    SelfAssessAnswer() => const Rejected(StudyModeRejection.unsupportedAction),
    AdvanceAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    if (answersInSession + 1 >= _turnCap) return const LeaveAtCap();
    return const ComeBack(afterTurns: _comeBackAfterTurns);
  }
}

const SelfAssessModeHandler selfAssessMode = SelfAssessModeHandler();

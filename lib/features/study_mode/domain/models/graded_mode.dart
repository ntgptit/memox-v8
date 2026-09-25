import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// The four graded modes (BR-MODE-011): a right or wrong verdict, mapped as
/// BR-MODE-012 says, and rounds that repeat the wrong cards until a round ends
/// with none, with no cap (BR-STUDY-059, BR-STUDY-069). Each mode judges its
/// own input (graded modes spec §7).
abstract base class GradedModeHandler extends StudyModeHandler {
  const GradedModeHandler();

  @override
  bool get usesRounds => true;

  /// The verdict of a right or wrong answer: right is `remembered`, wrong is
  /// `forgotten`, and every level short of right is wrong (BR-MODE-012,
  /// BR-STUDY-070). The other fields are what `review_log` keeps of the turn.
  Outcome<TurnVerdict, StudyModeRejection> verdictOf(
    bool isCorrect,
    SrsScheduler scheduler, {
    OutcomeReason? outcomeReason,
    int? comparisonVersion,
    bool? usedHint,
    String? takesMeaningSlotOf,
  }) => switch (_actionOf(isCorrect, scheduler)) {
    Rejected(:final reason) => Rejected(reason),
    Ok(value: final action) => Ok(
      TurnVerdict(
        action: action,
        isCorrect: isCorrect,
        outcomeReason: outcomeReason,
        comparisonVersion: comparisonVersion,
        usedHint: usedHint,
        takesMeaningSlotOf: takesMeaningSlotOf,
      ),
    ),
  };

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    return const LeaveAndEnroll();
  }
}

/// The action of a right or wrong answer, when [scheduler] has it.
Outcome<Object?, StudyModeRejection> _actionOf(
  bool isCorrect,
  SrsScheduler scheduler,
) {
  final action = isCorrect
      ? EightBoxAction.remembered
      : EightBoxAction.forgotten;
  if (!scheduler.supportedActions.contains(action)) {
    return const Rejected(StudyModeRejection.unsupportedAction);
  }
  return Ok(action);
}

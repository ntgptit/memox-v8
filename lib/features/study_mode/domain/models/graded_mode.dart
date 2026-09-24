import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The four graded modes (BR-MODE-011): a right or wrong verdict, mapped as
/// BR-MODE-012 says, and rounds that repeat the wrong cards until a round ends
/// with none, with no cap (BR-STUDY-059, BR-STUDY-069). `recall` uses this
/// class as it is; `match`, `guess` and `fill` add their data condition.
base class GradedModeHandler extends StudyModeHandler {
  const GradedModeHandler();

  @override
  bool get usesRounds => true;

  @override
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  ) {
    if (answer is! GradedAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final action = answer.isCorrect
        ? EightBoxAction.remembered
        : EightBoxAction.forgotten;
    if (!scheduler.supportedActions.contains(action)) {
      return const Rejected(StudyModeRejection.unsupportedAction);
    }
    return Ok(action);
  }

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    return const LeaveAndEnroll();
  }
}

const GradedModeHandler recallMode = GradedModeHandler();

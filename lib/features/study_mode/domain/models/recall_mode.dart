import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// The time of one `recall` turn, measured in interaction time by the screen
/// (BR-STUDY-031).
const recallTurnMs = 20000;

/// `recall`: the term is shown and the meaning hidden for [recallTurnMs].
/// Revealing the meaning records nothing; only the person's self-assessment
/// after it does, once, and the end of the time records wrong
/// (BR-STUDY-031 to BR-STUDY-036, BR-STUDY-065, BR-STUDY-066).
final class RecallModeHandler extends GradedModeHandler {
  const RecallModeHandler();

  @override
  int get turnTimeMs => recallTurnMs;

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) {
    if (answer is! RecallAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final outcome = answer.outcome;
    if (outcome == RecallOutcome.timedOut) {
      // Once the answer is shown, the time has stopped (BR-STUDY-032).
      if (context.isRevealed) {
        return const Rejected(StudyModeRejection.alreadyRevealed);
      }
      return verdictOf(false, scheduler, outcomeReason: OutcomeReason.timeout);
    }
    if (!context.isRevealed) {
      return const Rejected(StudyModeRejection.notRevealed);
    }
    return verdictOf(outcome == RecallOutcome.remembered, scheduler);
  }
}

const RecallModeHandler recallMode = RecallModeHandler();

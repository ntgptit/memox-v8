import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// The comparison policy a `fill` turn is judged by, stored on the turn: the
/// typed term, trimmed and lower-cased with its accents kept, against
/// `front_folded`. A change to the policy raises it and never touches the
/// turns already recorded (BR-STUDY-026, BR-STUDY-027).
const fillComparisonVersion = 1;

/// `fill`: the meaning is shown and the person types the term. Only a card
/// with an `example` can be asked; the others are skipped in this stage and
/// still take part in the rest (BR-STUDY-044, BR-STUDY-071).
final class FillModeHandler extends GradedModeHandler {
  const FillModeHandler();

  @override
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) {
    final withExample = [
      for (final card in cards)
        if (card.hasExample) card.cardId,
    ];
    if (withExample.isEmpty) {
      return const StageSkipped(ModeUnavailableReason.noExample);
    }
    return StageRuns(withExample);
  }

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) {
    if (answer is! FillAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final typed = foldText(answer.typed);
    if (typed.isEmpty) return const Rejected(StudyModeRejection.emptyAnswer);
    return verdictOf(
      typed == context.card.frontFolded,
      scheduler,
      comparisonVersion: fillComparisonVersion,
      usedHint: context.isHintShown,
    );
  }
}

const FillModeHandler fillMode = FillModeHandler();

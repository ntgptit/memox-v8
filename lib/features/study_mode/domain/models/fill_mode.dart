import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

/// `fill`: type the term. Only a card with an `example` can be asked; the
/// others are skipped in this stage and still take part in the rest
/// (BR-STUDY-044, BR-STUDY-071).
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
}

const FillModeHandler fillMode = FillModeHandler();

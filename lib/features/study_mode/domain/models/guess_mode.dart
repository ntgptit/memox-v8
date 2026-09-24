import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

/// Each question shows one answer and four distractors, five distinct
/// meanings in all (BR-STUDY-037, BR-STUDY-039).
const _optionCount = 5;

/// `guess`: pick the meaning among five. The stage runs when its distractor
/// source (the session's cards and the learned, active cards of the root's
/// tree, BR-STUDY-038) holds five distinct meanings, however few cards the
/// session has (BR-STUDY-040; spec D5; IT-MODE-015).
final class GuessModeHandler extends GradedModeHandler {
  const GuessModeHandler();

  @override
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) {
    if (distinctMeaningCount < _optionCount) {
      return const StageSkipped(ModeUnavailableReason.tooFewMeanings);
    }
    return super.eligibility(cards, distinctMeaningCount: distinctMeaningCount);
  }
}

const GuessModeHandler guessMode = GuessModeHandler();

import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

/// One pair on the board is its own answer (BR-STUDY-045).
const _minimumPairs = 2;

/// `match`: the pairs of a round on a board. A wrong pair keeps its row on
/// the board and sends the card to the next round (BR-STUDY-062), so any
/// pending row of the round can be answered.
final class MatchModeHandler extends GradedModeHandler {
  const MatchModeHandler();

  @override
  bool get servesInOrder => false;

  @override
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) {
    if (cards.length < _minimumPairs) {
      return const StageSkipped(ModeUnavailableReason.tooFewPairs);
    }
    return super.eligibility(cards, distinctMeaningCount: distinctMeaningCount);
  }

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    return const StayAndEnroll();
  }
}

const MatchModeHandler matchMode = MatchModeHandler();

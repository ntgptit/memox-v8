import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// `browse`: both sides at once, to get acquainted. No grade, no action, no
/// `review_log` row and no schedule change; the card leaves the queue once
/// the person moves on (BR-MODE-005, BR-MODE-006, BR-STUDY-007).
final class BrowseModeHandler extends StudyModeHandler {
  const BrowseModeHandler();

  @override
  bool get producesAction => false;

  @override
  bool get usesRounds => false;

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) => switch (answer) {
    AdvanceAnswer() => const Ok(TurnVerdict(action: null)),
    SelfAssessAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) =>
      const Leave();
}

const BrowseModeHandler browseMode = BrowseModeHandler();

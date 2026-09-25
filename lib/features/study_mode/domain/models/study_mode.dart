import 'dart:math';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/browse_mode.dart';
import 'package:memox/features/study_mode/domain/models/fill_mode.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/self_assess_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// The six ways a card is asked (BR-MODE-002), stored as a stable text code
/// on `study_session.current_mode`, `study_queue_items.mode` and
/// `review_log.mode` (BR-MODE-008).
enum StudyMode {
  browse('browse'),
  selfAssess('self_assess'),
  match('match'),
  guess('guess'),
  recall('recall'),
  fill('fill');

  const StudyMode(this.code);

  final String code;

  /// The mode a stored [code] names. An unknown code is corrupt data, never
  /// a reason to fall back to a default.
  static StudyMode fromCode(String code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    throw ArgumentError.value(code, 'code', 'unknown study mode code');
  }

  /// The one place a mode is told apart (guard
  /// `single_study_mode_dispatch`): every question about a mode is a member
  /// of its handler.
  StudyModeHandler get handler => switch (this) {
    StudyMode.browse => browseMode,
    StudyMode.selfAssess => selfAssessMode,
    StudyMode.match => matchMode,
    StudyMode.guess => guessMode,
    StudyMode.recall => recallMode,
    StudyMode.fill => fillMode,
  };
}

/// The stage chain of a learning session, declared per algorithm
/// (BR-MODE-004, BR-MODE-007; spec D4).
List<StudyMode> stageSequenceOf(SchedulerType type) => switch (type) {
  SchedulerType.eightBox => const [
    StudyMode.browse,
    StudyMode.match,
    StudyMode.guess,
    StudyMode.recall,
    StudyMode.fill,
  ],
  SchedulerType.sm2 => const [StudyMode.browse, StudyMode.selfAssess],
};

/// The modes a review offers: the stages of the chain that record an
/// action, so never `browse` (BR-STUDY-055).
List<StudyMode> reviewModesOf(SchedulerType type) => [
  for (final mode in stageSequenceOf(type))
    if (mode.handler.producesAction) mode,
];

/// A mode's policy (spec §5): what it needs of the cards, what an answer
/// means, and what a turn does to its queue row. Nothing here reads the
/// database; the study session hands the facts in and applies the decisions.
abstract base class StudyModeHandler {
  const StudyModeHandler();

  /// Whether a turn records an action: every mode but `browse`
  /// (BR-MODE-005, BR-MODE-011).
  bool get producesAction => true;

  /// Whether a wrong answer sends the card to a next round (BR-STUDY-059);
  /// `browse` and `self_assess` have no rounds (BR-STUDY-005).
  bool get usesRounds;

  /// Whether turns follow the queue one card at a time; `match` shows
  /// several rows of the round at once.
  bool get servesInOrder => true;

  /// Whether a direction can change which side is the prompt without
  /// changing what is graded (BR-MODE-013).
  bool get takesDirection => false;

  /// The cards of [cards] the stage asks, or why it cannot run on them
  /// (BR-MODE-009, BR-STUDY-071). [distinctMeaningCount] counts the distinct
  /// `back_folded` of the distractor source (spec D5).
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) => StageRuns([for (final card in cards) card.cardId]);

  /// The action [answer] records under [scheduler], null when the mode
  /// records none, or why [answer] does not fit (BR-MODE-011, BR-MODE-012).
  /// Package 2a's path, which [judge] replaces in Task 6.
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  );

  /// What [answer] makes of the turn [context] describes under [scheduler],
  /// or why it does not fit (graded modes spec §7.2). The session reads the
  /// facts and writes what the verdict says.
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  );

  /// Whether a question shows stored options, which the session then reads
  /// with their meaning source (`guess`, spec §7.7).
  bool get asksWithOptions => false;

  /// What the round of [rows] needs before it is served: nothing but for
  /// `match` boards and `guess` questions (spec §7.7).
  RoundPreparation prepareRound(
    List<RoundRowFacts> rows, {
    required List<MeaningCard> meaningSource,
    required Random random,
  }) => const RoundPreparation();

  /// What a turn does to its row: [lapsed] when its action was
  /// `forgotten`/`again`, after [answersInSession] earlier turns on that row
  /// (spec §5.5).
  RowStep stepAfter({required bool lapsed, required int answersInSession});
}

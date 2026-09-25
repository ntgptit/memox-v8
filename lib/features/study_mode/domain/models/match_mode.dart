import 'dart:math';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// One pair on the board is its own answer (BR-STUDY-045).
const _minimumPairs = 2;

/// The pairs a board shows at most (BR-STUDY-049).
const matchBoardSize = 5;

/// The board of the row at [position]: consecutive positions of the round,
/// [matchBoardSize] at a time; the last board takes what is left
/// (BR-STUDY-049).
int matchBoardOf(int position) => position ~/ matchBoardSize;

/// `match`: the pairs of a round on boards of [matchBoardSize]. A turn is the
/// term card's and is judged by meaning, so a meaning equal to the term's own
/// is right (BR-STUDY-062; spec D3). A wrong pair keeps its row on the board
/// and sends the card to the next round (BR-STUDY-062).
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
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) {
    if (answer is! MatchAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final meaning = context.boardMeanings[answer.meaningCardId];
    if (meaning == null) return const Rejected(StudyModeRejection.notOnBoard);
    final isCorrect = meaning == context.card.backFolded;
    final takesOtherSlot =
        isCorrect && answer.meaningCardId != context.card.cardId;
    return verdictOf(
      isCorrect,
      scheduler,
      takesMeaningSlotOf: takesOtherSlot ? answer.meaningCardId : null,
    );
  }

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    return const StayAndEnroll();
  }

  /// Meaning slots for every board with a row that lacks one, the matched
  /// pairs included; a board that has its slots keeps them (spec D7, D8).
  @override
  RoundPreparation prepareRound(
    List<RoundRowFacts> rows, {
    required List<MeaningCard> meaningSource,
    required Random random,
  }) {
    final boards = <int, List<RoundRowFacts>>{};
    for (final row in rows) {
      (boards[matchBoardOf(row.position)] ??= []).add(row);
    }
    final slots = <String, int>{};
    for (final board in boards.keys.toList()..sort()) {
      final pairs = boards[board]!
        ..sort((a, b) => a.position.compareTo(b.position));
      if (pairs.every((pair) => pair.meaningSlot != null)) continue;
      final shuffled = meaningSlotsFor(pairs.length, random);
      for (final (index, pair) in pairs.indexed) {
        slots[pair.cardId] = shuffled[index];
      }
    }
    return RoundPreparation(meaningSlots: slots);
  }
}

const MatchModeHandler matchMode = MatchModeHandler();

/// The slot of each meaning on a board of [pairCount] pairs, in the order of
/// its terms: a shuffle with [random] that never keeps that order when there
/// are two or more pairs; if it did, the first two swap (spec D7).
List<int> meaningSlotsFor(int pairCount, Random random) {
  final slots = [for (var slot = 0; slot < pairCount; slot++) slot]
    ..shuffle(random);
  if (pairCount < _minimumPairs) return slots;
  var keptOrder = true;
  for (var index = 0; index < pairCount; index++) {
    if (slots[index] != index) keptOrder = false;
  }
  if (!keptOrder) return slots;
  return [slots[1], slots[0], ...slots.skip(2)];
}

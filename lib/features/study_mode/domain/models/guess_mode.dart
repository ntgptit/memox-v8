import 'dart:math';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

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
  bool get asksWithOptions => true;

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

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) {
    if (answer is! GuessAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final options = context.guessOptionIds;
    if (options == null || options.length != _optionCount) {
      return const Rejected(StudyModeRejection.questionBlocked);
    }
    if (!options.contains(answer.chosenCardId)) {
      return const Rejected(StudyModeRejection.notAnOption);
    }
    return verdictOf(answer.chosenCardId == context.card.cardId, scheduler);
  }

  /// A question for every pending row that lacks its five options; a
  /// question with them is never built again (BR-STUDY-043; spec D8).
  @override
  RoundPreparation prepareRound(
    List<RoundRowFacts> rows, {
    required List<MeaningCard> meaningSource,
    required Random random,
  }) {
    final byPosition = [...rows]
      ..sort((a, b) => a.position.compareTo(b.position));
    return RoundPreparation(
      questions: {
        for (final row in byPosition)
          if (row.isPending && row.optionCount != _optionCount)
            row.cardId: guessOptionsFor(
              (cardId: row.cardId, meaningFolded: row.meaningFolded),
              meaningSource,
              random,
            ),
      },
    );
  }
}

const GuessModeHandler guessMode = GuessModeHandler();

/// The five options of a question on [asked], in the order shown, or null
/// when [source] holds fewer than four meanings besides [asked]'s, so the
/// question is blocked (BR-STUDY-037 to BR-STUDY-040; spec §7.5). One card
/// stands for each meaning, never one with [asked]'s meaning; the order is a
/// shuffle of its own, apart from the round's (BR-STUDY-043). Groups and
/// cards are sorted before drawing, so a seeded [random] repeats whatever
/// order [source] comes in.
List<String>? guessOptionsFor(
  MeaningCard asked,
  List<MeaningCard> source,
  Random random,
) {
  final cardsByMeaning = <String, List<String>>{};
  for (final card in source) {
    if (card.cardId == asked.cardId) continue;
    if (card.meaningFolded == asked.meaningFolded) continue;
    (cardsByMeaning[card.meaningFolded] ??= []).add(card.cardId);
  }
  if (cardsByMeaning.length < _optionCount - 1) return null;
  final meanings = cardsByMeaning.keys.toList()
    ..sort()
    ..shuffle(random);
  final options = [
    asked.cardId,
    for (final meaning in meanings.take(_optionCount - 1))
      _oneOf(cardsByMeaning[meaning]!..sort(), random),
  ];
  return options..shuffle(random);
}

String _oneOf(List<String> cardIds, Random random) =>
    cardIds[random.nextInt(cardIds.length)];

import 'dart:math';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The first round of one stage: its mode, its cards in serving order
/// (BR-STUDY-022) and, in a review that takes one, each card's direction
/// (BR-MODE-015).
final class StageQueue {
  const StageQueue(this.mode, this.cardIds, {this.directions});

  final StudyMode mode;
  final List<String> cardIds;

  /// One per card of [cardIds], in the same order; null when the session
  /// takes no direction (BR-MODE-013).
  final List<QuestionDirection>? directions;
}

/// The cards a learning session takes (UC-STUDY-001 step 3): at most
/// [options]' `card_limit` of [candidates], which come oldest first. `created`
/// takes the oldest, `random` draws with [random] (BR-STUDY-003,
/// BR-STUDY-057). The order only chooses the set: every stage shuffles it
/// again (IT-STUDY-012).
List<StudyCardFacts> newCardsToLearn(
  List<StudyCardFacts> candidates,
  StudyOptions options,
  Random random,
) {
  final ordered = switch (options.newCardOrder) {
    NewCardOrder.created => candidates,
    NewCardOrder.random => [...candidates]..shuffle(random),
  };
  return ordered.take(options.cardLimit).toList();
}

/// Round 1 of every stage of a learning session over [cards], all built
/// when the session opens so the queue never changes under it (BR-STUDY-021;
/// spec D7). A stage that cannot run has no queue (BR-MODE-009), a card a
/// stage cannot ask is left out of that stage only (BR-STUDY-071), and each
/// stage is shuffled on its own, unlike the stage before it (BR-STUDY-022).
List<StageQueue> learningQueues(
  SchedulerType type,
  List<StudyCardFacts> cards, {
  required int distinctMeaningCount,
  required Random random,
}) {
  final queues = <StageQueue>[];
  for (final mode in stageSequenceOf(type)) {
    final eligibility = mode.handler.eligibility(
      cards,
      distinctMeaningCount: distinctMeaningCount,
    );
    if (eligibility case StageRuns(:final cardIds)) {
      final previous = queues.isEmpty ? const <String>[] : queues.last.cardIds;
      queues.add(StageQueue(mode, shuffledUnlike(cardIds, previous, random)));
    }
  }
  return queues;
}

/// Round 1 of a review in [mode] over [dueCards], which come earliest due
/// first (UC-STUDY-001 step 4, UC-STUDY-003). The request is checked before
/// the cards, and all before anything is written (spec §7.1): [mode] must be
/// a review mode of [type] (modeNotOffered, BR-STUDY-055) and [direction]
/// given exactly when BR-MODE-013 takes one (directionRequired,
/// directionNotAllowed, BR-MODE-018); then a card must be due (nothingDue,
/// BR-STUDY-054) and the stage must run on the cards (modeUnavailable,
/// BR-MODE-009). Round 1 keeps the due order (BR-STUDY-002), and with a
/// direction every card gets one (BR-MODE-015).
Outcome<StageQueue, StudyRejection> reviewQueue(
  SchedulerType type,
  StudyMode mode, {
  required DirectionChoice? direction,
  required List<StudyCardFacts> dueCards,
  required int distinctMeaningCount,
  required Random random,
}) {
  if (!reviewModesOf(type).contains(mode)) {
    return const Rejected(StudyRejection.modeNotOffered);
  }
  final takesDirection = acceptsDirection(SessionKind.reviewing, type, mode);
  if (takesDirection && direction == null) {
    return const Rejected(StudyRejection.directionRequired);
  }
  if (!takesDirection && direction != null) {
    return const Rejected(StudyRejection.directionNotAllowed);
  }
  if (dueCards.isEmpty) return const Rejected(StudyRejection.nothingDue);
  final eligibility = mode.handler.eligibility(
    dueCards,
    distinctMeaningCount: distinctMeaningCount,
  );
  if (eligibility is! StageRuns) {
    return const Rejected(StudyRejection.modeUnavailable);
  }
  final cardIds = eligibility.cardIds;
  return Ok(
    StageQueue(
      mode,
      cardIds,
      directions: direction == null
          ? null
          : assignDirections(cardIds.length, direction, random),
    ),
  );
}

/// [cardIds] shuffled with [random], never in the order [previous] gave the
/// same cards (BR-STUDY-022, BR-STUDY-061): when two or more cards are in
/// both and the shuffle kept their order, the first two of them swap.
List<String> shuffledUnlike(
  List<String> cardIds,
  List<String> previous,
  Random random,
) {
  final order = [...cardIds]..shuffle(random);
  final before = previous.toSet();
  final shared = [
    for (final id in order)
      if (before.contains(id)) id,
  ];
  final kept = shared.toSet();
  final earlier = [
    for (final id in previous)
      if (kept.contains(id)) id,
  ];
  if (shared.length < 2 || !_sameOrder(shared, earlier)) return order;
  final first = order.indexOf(shared[0]);
  final second = order.indexOf(shared[1]);
  order[first] = shared[1];
  order[second] = shared[0];
  return order;
}

bool _sameOrder(List<String> a, List<String> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

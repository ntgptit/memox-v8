import 'dart:math';

import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The direction a review asks in, chosen once for the whole session
/// (BR-MODE-015, BR-MODE-017) and stored on `study_session.direction`.
enum DirectionChoice {
  koreanToMeaning('korean_to_meaning'),
  meaningToKorean('meaning_to_korean'),
  mixed('mixed');

  const DirectionChoice(this.code);

  final String code;

  static DirectionChoice fromCode(String code) {
    for (final choice in values) {
      if (choice.code == code) return choice;
    }
    throw ArgumentError.value(code, 'code', 'unknown direction choice');
  }
}

/// The direction of one card (BR-MODE-014), stored on
/// `study_queue_items.direction` and copied to `review_log.direction`
/// (BR-MODE-016).
enum QuestionDirection {
  /// `front` is the prompt, `back` the answer.
  koreanToMeaning('korean_to_meaning'),

  /// `back` is the prompt, `front` the answer.
  meaningToKorean('meaning_to_korean');

  const QuestionDirection(this.code);

  final String code;

  static QuestionDirection fromCode(String code) {
    for (final direction in values) {
      if (direction.code == code) return direction;
    }
    throw ArgumentError.value(code, 'code', 'unknown question direction');
  }
}

/// The one predicate of BR-MODE-013: a review of an `sm2` deck in a mode
/// that takes a direction, which only `self_assess` does.
bool acceptsDirection(SessionKind kind, SchedulerType type, StudyMode mode) =>
    kind == SessionKind.reviewing &&
    type == SchedulerType.sm2 &&
    mode.handler.takesDirection;

/// One direction per card, once, when the queue is written (BR-MODE-015). A
/// fixed choice gives every card that direction. `mixed` gives each
/// direction half of the cards, [random] picking the side of an odd card,
/// and deals them across the cards.
List<QuestionDirection> assignDirections(
  int count,
  DirectionChoice choice,
  Random random,
) => switch (choice) {
  DirectionChoice.koreanToMeaning => List.filled(
    count,
    QuestionDirection.koreanToMeaning,
  ),
  DirectionChoice.meaningToKorean => List.filled(
    count,
    QuestionDirection.meaningToKorean,
  ),
  DirectionChoice.mixed => _mixed(count, random),
};

List<QuestionDirection> _mixed(int count, Random random) {
  final half = count ~/ 2;
  final odd = random.nextBool()
      ? QuestionDirection.koreanToMeaning
      : QuestionDirection.meaningToKorean;
  return [
    ...List.filled(half, QuestionDirection.koreanToMeaning),
    ...List.filled(half, QuestionDirection.meaningToKorean),
    if (count.isOdd) odd,
  ]..shuffle(random);
}

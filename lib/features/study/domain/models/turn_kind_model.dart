import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

/// The kind of a turn (BR-STUDY-023; spec D8). A card's first turn in a
/// stage, on its round 1 row with no answer yet, is `learning` in a learning
/// session and `scheduled` in a review; every later turn of the card in that
/// stage (a comeback, a retry on the board, a next round) is `relearning`.
ReviewKind turnKindOf(
  SessionKind session, {
  required int round,
  required int answersInSession,
}) {
  if (round > 1 || answersInSession > 0) return ReviewKind.relearning;
  return switch (session) {
    SessionKind.learning => ReviewKind.learning,
    SessionKind.reviewing => ReviewKind.scheduled,
  };
}

import 'package:memox/features/srs/domain/models/review_kind_model.dart';

/// One answer a study session records (UC-STUDY-001 steps 7–9). The session
/// decides [kind] (BR-SRS-015) and hands over what `review_log` keeps of it:
/// [modeCode] and [directionCode] are the stored codes of the study mode and
/// of the row's direction, passed as text because `srs` is the base feature
/// and does not import `study_mode` (ADR-011).
final class ReviewTurn {
  const ReviewTurn({
    required this.cardId,
    required this.sessionId,
    required this.generation,
    required this.kind,
    required this.modeCode,
    required this.action,
    required this.answeredAt,
    this.directionCode,
    this.outcomeReasonCode,
    this.comparisonVersion,
    this.usedHint,
  });

  final String cardId;
  final String sessionId;

  /// The session's generation (BR-SRS-025, BR-SRS-026).
  final int generation;
  final ReviewKind kind;
  final String modeCode;

  /// One of the root scheduler's `supportedActions`.
  final Object action;
  final String? directionCode;
  final DateTime answeredAt;

  /// What the mode adds to the turn, passed the way [modeCode] is: the code
  /// of the reason a `recall` turn ended (BR-STUDY-034), and the comparison
  /// version and the shown hint of a `fill` turn (BR-STUDY-027,
  /// BR-STUDY-028). The schema refuses them on any other mode.
  final String? outcomeReasonCode;
  final int? comparisonVersion;
  final bool? usedHint;
}

import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// One time a person takes one test (BR-TOPIK-010). [completedAt], [score],
/// [correctCount] and [answeredCount] are null exactly while the attempt is
/// in progress (BR-TOPIK-013).
final class TopikAttempt {
  const TopikAttempt({
    required this.id,
    required this.testId,
    required this.level,
    required this.section,
    required this.round,
    required this.mode,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.updatedAt,
    required this.totalTimeMs,
    required this.currentQuestionNo,
    required this.questionCount,
    required this.maxScore,
    required this.score,
    required this.correctCount,
    required this.answeredCount,
    required this.contentVersion,
  });

  final String id;
  final String testId;
  final TopikLevel level;
  final TopikSection section;
  final int round;
  final TopikAttemptMode mode;
  final TopikAttemptStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// The last write: an answer, a move, a time record or the submit.
  final DateTime updatedAt;

  /// The sum of the answers' time, in milliseconds (BR-TOPIK-015).
  final int totalTimeMs;

  /// The question the attempt shows; time accrues to it (BR-TOPIK-015).
  final int currentQuestionNo;
  final int questionCount;
  final int maxScore;
  final int? score;
  final int? correctCount;
  final int? answeredCount;

  /// The content version the attempt started on, then the one it was scored
  /// on (BR-TOPIK-019).
  final int contentVersion;

  bool get isCompleted => status == TopikAttemptStatus.completed;
}

/// One question of an attempt. [selectedIdx] is the chosen option (1–4) or
/// null (BR-TOPIK-003, BR-TOPIK-012). [correctIdx], [points] and
/// [pointsEarned] are the snapshot taken at submit, null while the attempt is
/// in progress (BR-TOPIK-013). [questionType] is null then too, and also for
/// a type code this build does not know (an attempt synced from a newer app).
final class TopikAttemptAnswer {
  const TopikAttemptAnswer({
    required this.questionNo,
    required this.selectedIdx,
    required this.timeSpentMs,
    required this.answeredAt,
    required this.correctIdx,
    required this.points,
    required this.pointsEarned,
    required this.questionType,
  });

  final int questionNo;
  final int? selectedIdx;
  final int timeSpentMs;
  final DateTime? answeredAt;
  final int? correctIdx;
  final int? points;
  final int? pointsEarned;
  final TopikQuestionType? questionType;

  /// Null while the attempt is in progress: nothing tells right from wrong
  /// before submit (BR-TOPIK-016).
  TopikAnswerStatus? get status {
    final correct = correctIdx;
    if (correct == null) return null;
    if (selectedIdx == null) return TopikAnswerStatus.unanswered;
    return selectedIdx == correct
        ? TopikAnswerStatus.correct
        : TopikAnswerStatus.wrong;
  }
}

/// An attempt with its answers in question order.
final class TopikAttemptDetail {
  const TopikAttemptDetail({required this.attempt, required this.answers});

  final TopikAttempt attempt;
  final List<TopikAttemptAnswer> answers;
}

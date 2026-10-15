import 'package:memox/core/database/app_database.dart'
    show TopikAttemptAnswerRow, TopikAttemptRow;
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// [row] as the domain model. The schema's CHECKs keep `level` and `section`
/// to known codes, so an unknown one is a broken database, not data.
TopikAttempt topikAttemptOf(TopikAttemptRow row) => TopikAttempt(
  id: row.id,
  testId: row.testId,
  level:
      TopikLevel.ofCode(row.level) ??
      (throw StateError('unknown TOPIK level ${row.level}')),
  section:
      TopikSection.ofCode(row.section) ??
      (throw StateError('unknown TOPIK section ${row.section}')),
  round: row.round,
  mode: TopikAttemptMode.fromCode(row.mode),
  status: TopikAttemptStatus.fromCode(row.status),
  startedAt: row.startedAt,
  completedAt: row.completedAt,
  updatedAt: row.updatedAt,
  totalTimeMs: row.totalTimeMs,
  currentQuestionNo: row.currentQuestionNo,
  questionCount: row.questionCount,
  maxScore: row.maxScore,
  score: row.score,
  correctCount: row.correctCount,
  answeredCount: row.answeredCount,
  contentVersion: row.contentVersion,
);

/// [row] as the domain model; a type code this build does not know reads as
/// null (an attempt synced from a newer app).
TopikAttemptAnswer topikAttemptAnswerOf(TopikAttemptAnswerRow row) =>
    TopikAttemptAnswer(
      questionNo: row.questionNo,
      selectedIdx: row.selectedIdx,
      timeSpentMs: row.timeSpentMs,
      answeredAt: row.answeredAt,
      correctIdx: row.correctIdx,
      points: row.points,
      pointsEarned: row.pointsEarned,
      questionType: TopikQuestionType.ofCode(row.questionType),
    );

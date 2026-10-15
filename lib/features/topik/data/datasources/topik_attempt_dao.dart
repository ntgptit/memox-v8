import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

part 'topik_attempt_dao.g.dart';

/// Row access for `topik_attempt` and `topik_attempt_answer`
/// (`topik_queries.drift`). It returns Drift rows, never domain values, and
/// runs inside the caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/topik_queries.drift'},
)
final class TopikAttemptDao extends DatabaseAccessor<AppDatabase>
    with _$TopikAttemptDaoMixin {
  TopikAttemptDao(super.attachedDatabase);

  Future<TopikAttemptRow?> attemptRow(String id) =>
      topikAttemptById(id).getSingleOrNull();

  Future<TopikAttemptRow?> openAttemptOf(String testId) =>
      openTopikAttemptOfTest(testId).getSingleOrNull();

  Future<List<TopikAttemptAnswerRow>> answerRows(String attemptId) =>
      topikAnswersOfAttempt(attemptId).get();

  Stream<List<TopikAttemptRow>> watchAttemptRowsOf(String testId) =>
      topikAttemptsOfTest(testId).watch();

  Stream<List<TopikAttemptRow>> watchAllAttemptRows() =>
      allTopikAttempts().watch();

  /// Fires once, then after every write to an attempt or an answer.
  Stream<void> attemptChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.topikAttempt,
    attachedDatabase.topikAttemptAnswer,
  ]);

  Future<void> insertAttempt({
    required String id,
    required String testId,
    required String level,
    required String section,
    required int round,
    required String mode,
    required DateTime startedAt,
    required int currentQuestionNo,
    required int questionCount,
    required int maxScore,
    required int contentVersion,
  }) => insertTopikAttempt(
    id,
    testId,
    level,
    section,
    round,
    mode,
    startedAt,
    currentQuestionNo,
    questionCount,
    maxScore,
    contentVersion,
  );

  Future<void> insertAnswer(String attemptId, int questionNo) =>
      insertTopikAnswer(attemptId, questionNo);

  /// Adds [elapsedMs] to [questionNo] and to the total, and makes [toQuestionNo]
  /// current.
  Future<void> addTime({
    required String attemptId,
    required int questionNo,
    required int elapsedMs,
    required int toQuestionNo,
    required DateTime at,
  }) async {
    await addTopikAnswerTime(elapsedMs, attemptId, questionNo);
    await advanceTopikAttempt(elapsedMs, toQuestionNo, at, attemptId);
  }

  Future<void> choose({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required DateTime at,
  }) => chooseTopikAnswer(selectedIdx, at, attemptId, questionNo);

  Future<void> snapshotAnswer({
    required String attemptId,
    required int questionNo,
    required int correctIdx,
    required int points,
    required int pointsEarned,
    required String questionType,
  }) => snapshotTopikAnswer(
    correctIdx,
    points,
    pointsEarned,
    questionType,
    attemptId,
    questionNo,
  );

  Future<void> complete({
    required String id,
    required DateTime at,
    required int score,
    required int maxScore,
    required int correctCount,
    required int answeredCount,
    required int questionCount,
    required int contentVersion,
  }) => completeTopikAttempt(
    at,
    score,
    maxScore,
    correctCount,
    answeredCount,
    questionCount,
    contentVersion,
    id,
  );

  Future<int> deleteAttempt(String id) => deleteTopikAttempt(id);
}

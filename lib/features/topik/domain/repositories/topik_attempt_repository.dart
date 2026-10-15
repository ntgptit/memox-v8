import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';

/// The attempts on this device (spec §5, §13.5). The one implementation is
/// `TopikAttemptRepositoryImpl`; the contract keeps domain free of Drift and
/// lets tests substitute a fake (ADR-010). Every write is one transaction and
/// a refusal writes nothing. `elapsedMs` is the time since the last write;
/// it is added to the attempt's current question before anything else
/// (BR-TOPIK-015), and a negative value is an `ArgumentError`.
abstract interface class TopikAttemptRepository {
  /// The attempts of [testId], newest first (BR-TOPIK-021).
  Stream<List<TopikAttempt>> watchAttemptsOfTest(String testId);

  /// [attemptId] with its answers in question order; null once it is gone
  /// (BR-TOPIK-018, BR-TOPIK-027).
  Stream<TopikAttemptDetail?> watchAttempt(String attemptId);

  /// The status of every test with an attempt, keyed by test id; a test
  /// without one is not started (BR-TOPIK-022).
  Stream<Map<String, TopikTestStatus>> watchTestStatuses();

  /// A new attempt of [test] in progress, one blank answer per question, the
  /// first question current (BR-TOPIK-010). inProgressExists when the test
  /// already has one on this device (BR-TOPIK-011).
  Future<Outcome<TopikAttempt, TopikRejection>> start(
    TopikTest test, {
    DateTime? now,
  });

  /// Start new, confirmed: the attempt of [test] in progress, if any, is
  /// deleted with its answers and a new one started, in one transaction
  /// (BR-TOPIK-011).
  Future<TopikAttempt> replaceInProgressAndStart(
    TopikTest test, {
    DateTime? now,
  });

  /// Chooses [selectedIdx] on [questionNo], replacing an earlier choice, and
  /// makes it current (BR-TOPIK-012). notFound, attemptCompleted,
  /// unknownQuestion, invalidOption.
  Future<Outcome<void, TopikRejection>> answer({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required int elapsedMs,
    DateTime? now,
  });

  /// Makes [toQuestionNo] current (spec §5.1). notFound, attemptCompleted,
  /// unknownQuestion.
  Future<Outcome<void, TopikRejection>> move({
    required String attemptId,
    required int toQuestionNo,
    required int elapsedMs,
    DateTime? now,
  });

  /// Records time on the current question: background, exit
  /// (BR-TOPIK-015). notFound, attemptCompleted.
  Future<Outcome<void, TopikRejection>> recordTime({
    required String attemptId,
    required int elapsedMs,
    DateTime? now,
  });

  /// Records the last time, scores the attempt against [test] (the content
  /// at submit), snapshots every answer and completes the attempt, queued
  /// for sync in the same transaction (BR-TOPIK-013, BR-TOPIK-026).
  /// notFound, attemptCompleted, contentMismatch (BR-TOPIK-019).
  Future<Outcome<TopikAttempt, TopikRejection>> submit({
    required String attemptId,
    required TopikTest test,
    required int elapsedMs,
    DateTime? now,
  });

  /// Deletes [attemptId] with its answers; a submitted one is queued as a
  /// final delete (BR-TOPIK-018). notFound.
  Future<Outcome<void, TopikRejection>> delete(String attemptId);
}

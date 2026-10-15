import 'package:memox/core/database/app_database.dart'
    show AppDatabase, TopikAttemptAnswerRow, TopikAttemptRow;
import 'package:memox/core/database/mapped_transaction.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/topik/data/datasources/topik_attempt_dao.dart';
import 'package:memox/features/topik/data/mappers/topik_attempt_mapper.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_score_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// The attempts on this device (spec §13.1, §13.5). Every write is one
/// transaction that reads the rows as they are at the moment of writing; the
/// schema's CHECKs and triggers back the refusals up.
final class TopikAttemptRepositoryImpl implements TopikAttemptRepository {
  TopikAttemptRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = TopikAttemptDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final TopikAttemptDao _dao;
  final DateTime Function() _now;

  @override
  Stream<List<TopikAttempt>> watchAttemptsOfTest(String testId) =>
      throw UnimplementedError('Task 5');

  @override
  Stream<TopikAttemptDetail?> watchAttempt(String attemptId) =>
      throw UnimplementedError('Task 5');

  @override
  Stream<Map<String, TopikTestStatus>> watchTestStatuses() =>
      throw UnimplementedError('Task 5');

  @override
  Future<Outcome<TopikAttempt, TopikRejection>> start(
    TopikTest test, {
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      if (await _dao.openAttemptOf(test.testId) != null) {
        return const Rejected(TopikRejection.inProgressExists);
      }
      return Ok(await _insert(test, at));
    });
  }

  @override
  Future<TopikAttempt> replaceInProgressAndStart(
    TopikTest test, {
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      final open = await _dao.openAttemptOf(test.testId);
      if (open != null) await _dao.deleteAttempt(open.id);
      return _insert(test, at);
    });
  }

  @override
  Future<Outcome<void, TopikRejection>> answer({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required int elapsedMs,
    DateTime? now,
  }) {
    final negative = _negativeElapsed(elapsedMs);
    if (negative != null) return Future.error(negative);
    if (!topikOptionIdxs.contains(selectedIdx)) {
      return Future.value(const Rejected(TopikRejection.invalidOption));
    }
    final at = now ?? _now();
    return _onOpenAttempt(attemptId, (row, numbers) async {
      if (!numbers.contains(questionNo)) {
        return const Rejected(TopikRejection.unknownQuestion);
      }
      await _addTime(row, elapsedMs, questionNo, at);
      await _dao.choose(
        attemptId: attemptId,
        questionNo: questionNo,
        selectedIdx: selectedIdx,
        at: at,
      );
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, TopikRejection>> move({
    required String attemptId,
    required int toQuestionNo,
    required int elapsedMs,
    DateTime? now,
  }) {
    final negative = _negativeElapsed(elapsedMs);
    if (negative != null) return Future.error(negative);
    final at = now ?? _now();
    return _onOpenAttempt(attemptId, (row, numbers) async {
      if (!numbers.contains(toQuestionNo)) {
        return const Rejected(TopikRejection.unknownQuestion);
      }
      await _addTime(row, elapsedMs, toQuestionNo, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, TopikRejection>> recordTime({
    required String attemptId,
    required int elapsedMs,
    DateTime? now,
  }) {
    final negative = _negativeElapsed(elapsedMs);
    if (negative != null) return Future.error(negative);
    final at = now ?? _now();
    return _onOpenAttempt(attemptId, (row, _) async {
      await _addTime(row, elapsedMs, row.currentQuestionNo, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<TopikAttempt, TopikRejection>> submit({
    required String attemptId,
    required TopikTest test,
    required int elapsedMs,
    DateTime? now,
  }) {
    final negative = _negativeElapsed(elapsedMs);
    if (negative != null) return Future.error(negative);
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      final row = await _dao.attemptRow(attemptId);
      if (row == null) return const Rejected(TopikRejection.notFound);
      if (row.status != TopikAttemptStatus.inProgress.code) {
        return const Rejected(TopikRejection.attemptCompleted);
      }
      final answers = await _dao.answerRows(attemptId);
      if (!_sameQuestions(row, answers, test)) {
        return const Rejected(TopikRejection.contentMismatch);
      }
      await _addTime(row, elapsedMs, row.currentQuestionNo, at);
      final scored = scoreTopikAttempt(test, {
        for (final answer in answers) answer.questionNo: answer.selectedIdx,
      });
      for (final answer in scored.answers) {
        await _dao.snapshotAnswer(
          attemptId: attemptId,
          questionNo: answer.questionNo,
          correctIdx: answer.correctIdx,
          points: answer.points,
          pointsEarned: answer.pointsEarned,
          questionType: answer.questionType.code,
        );
      }
      await _dao.complete(
        id: attemptId,
        at: at,
        score: scored.score,
        maxScore: scored.maxScore,
        correctCount: scored.correctCount,
        answeredCount: scored.answeredCount,
        questionCount: scored.questionCount,
        contentVersion: test.contentVersion,
      );
      return Ok(topikAttemptOf((await _dao.attemptRow(attemptId))!));
    });
  }

  @override
  Future<Outcome<void, TopikRejection>> delete(String attemptId) =>
      _db.mappedTransaction(() async {
        final deleted = await _dao.deleteAttempt(attemptId);
        if (deleted == 0) return const Rejected(TopikRejection.notFound);
        return const Ok(null);
      });

  Future<TopikAttempt> _insert(TopikTest test, DateTime at) async {
    final numbers = [for (final question in test.questions) question.no]
      ..sort();
    final id = newId();
    await _dao.insertAttempt(
      id: id,
      testId: test.testId,
      level: test.level.code,
      section: test.section.code,
      round: test.round,
      mode: TopikAttemptMode.practice.code,
      startedAt: at,
      currentQuestionNo: numbers.first,
      questionCount: numbers.length,
      maxScore: test.questions.fold(0, (sum, q) => sum + q.points),
      contentVersion: test.contentVersion,
    );
    for (final no in numbers) {
      await _dao.insertAnswer(id, no);
    }
    return topikAttemptOf((await _dao.attemptRow(id))!);
  }

  /// Runs [write] on [attemptId] when it exists and is in progress, with the
  /// attempt's question numbers; notFound or attemptCompleted otherwise.
  Future<Outcome<void, TopikRejection>> _onOpenAttempt(
    String attemptId,
    Future<Outcome<void, TopikRejection>> Function(
      TopikAttemptRow row,
      Set<int> questionNos,
    )
    write,
  ) => _db.mappedTransaction(() async {
    final row = await _dao.attemptRow(attemptId);
    if (row == null) return const Rejected(TopikRejection.notFound);
    if (row.status != TopikAttemptStatus.inProgress.code) {
      return const Rejected(TopikRejection.attemptCompleted);
    }
    final numbers = {
      for (final answer in await _dao.answerRows(attemptId)) answer.questionNo,
    };
    return write(row, numbers);
  });

  /// Adds [elapsedMs] to the question that was current, then makes
  /// [toQuestionNo] current (BR-TOPIK-015).
  Future<void> _addTime(
    TopikAttemptRow row,
    int elapsedMs,
    int toQuestionNo,
    DateTime at,
  ) => _dao.addTime(
    attemptId: row.id,
    questionNo: row.currentQuestionNo,
    elapsedMs: elapsedMs,
    toQuestionNo: toQuestionNo,
    at: at,
  );

  /// Whether [test] is the attempt's test with exactly its questions
  /// (BR-TOPIK-019).
  static bool _sameQuestions(
    TopikAttemptRow row,
    List<TopikAttemptAnswerRow> answers,
    TopikTest test,
  ) {
    if (test.testId != row.testId) return false;
    final stored = {for (final answer in answers) answer.questionNo};
    final current = {for (final question in test.questions) question.no};
    return stored.length == current.length && stored.containsAll(current);
  }

  /// A negative [elapsedMs] is a programming error, delivered through the
  /// returned future like any other error of the write.
  static ArgumentError? _negativeElapsed(int elapsedMs) => elapsedMs < 0
      ? ArgumentError.value(elapsedMs, 'elapsedMs', 'must not be negative')
      : null;
}

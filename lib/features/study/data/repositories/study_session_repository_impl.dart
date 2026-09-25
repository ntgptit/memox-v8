import 'dart:math';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_round_data_source.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/data/datasources/study_turn_data_source.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// Runs a session: its turns, its rounds and stages, and how it ends
/// (UC-STUDY-001 steps 6–13, A1–A5); its screen reads through
/// `StudySessionViewRepositoryImpl`. Every write is one transaction, which
/// the srs and card writes it calls join: the rules read the rows as they
/// are at the moment of writing, and a refusal writes nothing.
final class StudySessionRepositoryImpl implements StudySessionRepository {
  StudySessionRepositoryImpl(
    this._db,
    ScheduleRepository schedules,
    CardRepository cards, {
    DateTime Function()? now,
    Random? random,
  }) : _dao = StudySessionDao(_db),
       _queue = StudyQueueDao(_db),
       _turns = StudyTurnDataSource(_db, schedules, cards),
       _rounds = StudyRoundDataSource(_db, random ?? Random()),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final StudySessionDao _dao;
  final StudyQueueDao _queue;

  /// Writes each answered turn.
  final StudyTurnDataSource _turns;

  /// Builds later rounds and prepares every round the session moves to.
  final StudyRoundDataSource _rounds;
  final DateTime Function() _now;

  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      switch (await _live(await _dao.sessionRow(sessionId), at)) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: (final session, final root)):
          final type = SchedulerType.fromCode(root.schedulerType!);
          final result = await _turns.answer(session, type, cardId, answer, at);
          if (result is Ok) await _progress(session, type, at);
          return result;
      }
    });
  }

  @override
  Future<Outcome<void, StudyRejection>> revealRecallAnswer({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) => _onServedRow(sessionId, cardId, StudyMode.recall, now, (row) async {
    if (row.isRevealed == 1) return const Ok(null);
    await _queue.reveal(row, remainingMs: _timeLeft(row, remainingMs));
    return const Ok(null);
  });

  @override
  Future<Outcome<void, StudyRejection>> saveRecallTime({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) => _onServedRow(sessionId, cardId, StudyMode.recall, now, (row) async {
    if (row.isRevealed == 1) return const Ok(null);
    await _queue.saveTimeLeft(row, remainingMs: _timeLeft(row, remainingMs));
    return const Ok(null);
  });

  @override
  Future<Outcome<void, StudyRejection>> showFillHint({
    required String sessionId,
    required String cardId,
    DateTime? now,
  }) => _onServedRow(sessionId, cardId, StudyMode.fill, now, (row) async {
    if (!await _dao.hasHint(cardId)) {
      return const Rejected(StudyRejection.noHint);
    }
    if (row.hintShown == 0) await _queue.showHint(row);
    return const Ok(null);
  });

  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final session = await _dao.sessionRow(sessionId);
      if (session == null) return const Rejected(StudyRejection.notFound);
      if (session.status != SessionStatus.inProgress.code) {
        return const Rejected(StudyRejection.sessionClosed);
      }
      await _dao.endSession(
        sessionId,
        status: SessionStatus.abandoned,
        reason: SessionEndReason.userExit,
        now: at,
      );
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, StudyRejection>> resumeSession({
    required String sessionId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final session = await _dao.sessionRow(sessionId);
      if (session != null &&
          session.status == SessionStatus.inProgress.code &&
          session.startedAt.isBefore(startOfLocalDay(at))) {
        await _dao.endSession(
          sessionId,
          status: SessionStatus.abandoned,
          reason: SessionEndReason.interrupted,
          now: at,
        );
        return const Rejected(StudyRejection.sessionExpired);
      }
      switch (await _live(session, at)) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: (final open, final root)):
          await _progress(
            open,
            SchedulerType.fromCode(root.schedulerType!),
            at,
          );
          await _prepareServed(sessionId);
          return const Ok(null);
      }
    });
  }

  @override
  Future<void> abandonStaleSessions({DateTime? now}) {
    final at = now ?? _now();
    return _write(
      () => _dao.closeStaleSessions(now: at, startOfToday: startOfLocalDay(at)),
    );
  }

  @override
  Future<void> failSession({required String sessionId, DateTime? now}) {
    final at = now ?? _now();
    return _write(() async {
      final session = await _dao.sessionRow(sessionId);
      if (session?.status != SessionStatus.inProgress.code) return;
      await _dao.endSession(
        sessionId,
        status: SessionStatus.failed,
        reason: SessionEndReason.persistenceError,
        now: at,
      );
    });
  }

  /// [write] on the row [sessionId] serves: the checks of a turn, for a write
  /// that is not one (graded modes spec §8.3). The session is open at its
  /// root's generation, in [mode], and serves [cardId].
  Future<Outcome<void, StudyRejection>> _onServedRow(
    String sessionId,
    String cardId,
    StudyMode mode,
    DateTime? now,
    Future<Outcome<void, StudyRejection>> Function(StudyQueueItem row) write,
  ) {
    final at = now ?? _now();
    return _write(() async {
      switch (await _live(await _dao.sessionRow(sessionId), at)) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: (final session, _)):
          if (session.currentMode != mode.code) {
            return const Rejected(StudyRejection.answerDoesNotFitMode);
          }
          final row = await _queue.headRow(
            session.id,
            mode.code,
            session.cursor,
          );
          if (row == null || row.cardId != cardId) {
            return const Rejected(StudyRejection.notCurrentCard);
          }
          return write(row);
      }
    });
  }

  /// [session] and its root while the session is open and its generation
  /// still holds (spec §7.3 step 1). A session whose root was reset since it
  /// opened is invalidated on the way (BR-STUDY-017, IT-CONT-010).
  Future<Outcome<(StudySession, Deck), StudyRejection>> _live(
    StudySession? session,
    DateTime at,
  ) async {
    if (session == null) return const Rejected(StudyRejection.notFound);
    if (session.status != SessionStatus.inProgress.code) {
      return const Rejected(StudyRejection.sessionClosed);
    }
    final root = await _dao.deckRow(session.rootId);
    if (root == null) return const Rejected(StudyRejection.notFound);
    if (root.generation == session.generation) return Ok((session, root));
    await _dao.endSession(
      session.id,
      status: SessionStatus.invalidated,
      reason: SessionEndReason.staleGeneration,
      now: at,
    );
    return const Rejected(StudyRejection.staleGeneration);
  }

  /// When the current round has no pending row left, the next round is
  /// built, or the session moves to the next stage that has rows, or, with
  /// none left, completes (spec §7.4; BR-STUDY-013, BR-STUDY-069).
  Future<void> _progress(
    StudySession session,
    SchedulerType type,
    DateTime at,
  ) async {
    final current = StudyMode.fromCode(session.currentMode);
    final chain = switch (SessionKind.values.byName(session.sessionKind)) {
      SessionKind.learning => stageSequenceOf(type),
      SessionKind.reviewing => [current],
    };
    for (final mode in chain.skipWhile((mode) => mode != current)) {
      final round = await _queue.lowestPendingRound(session.id, mode.code);
      if (round == null) continue;
      if (await _queue.isUnbuilt(session.id, mode.code, round)) {
        await _rounds.build(session.id, session.rootId, mode, round);
      } else if (mode != current) {
        // Round 1 of a later stage, built when the session opened, is
        // prepared when the stage starts (graded modes spec D8).
        await _rounds.prepare(session.id, session.rootId, mode, round);
      }
      if (mode != current) await _dao.setCurrentMode(session.id, mode.code);
      return;
    }
    await _dao.endSession(session.id, status: SessionStatus.completed, now: at);
  }

  /// Continue fills in what the round the session serves lacks: the
  /// questions and slots of a session from before v2, or a question that
  /// lost an option to a deleted card (graded modes spec §6.5, §8.2).
  Future<void> _prepareServed(String sessionId) async {
    final session = await _dao.sessionRow(sessionId);
    if (session?.status != SessionStatus.inProgress.code) return;
    final round = await _queue.lowestPendingRound(
      sessionId,
      session!.currentMode,
    );
    if (round == null) return;
    await _rounds.prepare(
      sessionId,
      session.rootId,
      StudyMode.fromCode(session.currentMode),
      round,
    );
  }

  /// One transaction. An unexpected database error leaves as the [Failure]
  /// `mapDatabaseError` makes of it, with its stack trace, after the rollback.
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

/// The time left of [row]'s turn after a save of [remainingMs]: it never
/// grows (BR-STUDY-036).
int _timeLeft(StudyQueueItem row, int remainingMs) =>
    min(row.remainingMs ?? recallTurnMs, remainingMs);

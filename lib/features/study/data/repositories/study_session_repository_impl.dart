import 'dart:math';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// Runs a session: its turns, its rounds and stages, and how it ends
/// (UC-STUDY-001 steps 6–13, A1–A5). Every write is one transaction, which
/// the srs and card writes it calls join: the rules read the rows as they
/// are at the moment of writing, and a refusal writes nothing.
final class StudySessionRepositoryImpl implements StudySessionRepository {
  StudySessionRepositoryImpl(
    this._db,
    this._schedules,
    this._cards, {
    DateTime Function()? now,
    Random? random,
  }) : _dao = StudySessionDao(_db),
       _queue = StudyQueueDao(_db),
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  final AppDatabase _db;
  final ScheduleRepository _schedules;
  final CardRepository _cards;
  final StudySessionDao _dao;
  final StudyQueueDao _queue;
  final DateTime Function() _now;

  /// Every shuffle of a later round (BR-STUDY-061).
  final Random _random;

  @override
  Future<Outcome<void, StudyRejection>> answerTurn({
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
          return _answer(session, root, cardId, answer, at);
      }
    });
  }

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

  /// [answer] on [cardId] in an open [session] (spec §7.3 steps 2–8).
  Future<Outcome<void, StudyRejection>> _answer(
    StudySession session,
    Deck root,
    String cardId,
    StudyAnswer answer,
    DateTime at,
  ) async {
    final mode = StudyMode.fromCode(session.currentMode);
    final row = mode.handler.servesInOrder
        ? await _queue.headRow(session.id, mode.code, session.cursor)
        : await _queue.boardRow(session.id, mode.code, cardId);
    if (row == null || row.cardId != cardId) {
      return const Rejected(StudyRejection.notCurrentCard);
    }

    final type = SchedulerType.fromCode(root.schedulerType!);
    final scheduler = schedulerFor(type);
    final Object? action;
    switch (mode.handler.actionOf(answer, scheduler)) {
      case Rejected(:final reason):
        return Rejected(StudyRejection.ofModeRefusal(reason));
      case Ok(:final value):
        action = value;
    }
    final kind = SessionKind.values.byName(session.sessionKind);
    if (action != null) {
      final recorded = await _schedules.recordTurn(
        ReviewTurn(
          cardId: cardId,
          sessionId: session.id,
          generation: session.generation,
          kind: turnKindOf(
            kind,
            round: row.round,
            answersInSession: row.answersInSession,
          ),
          modeCode: mode.code,
          action: action,
          directionCode: row.direction,
          answeredAt: at,
        ),
      );
      if (recorded case Rejected(:final reason)) {
        return Rejected(StudyRejection.ofTurnRefusal(reason));
      }
    }

    final cursor = session.cursor + 1;
    final step = mode.handler.stepAfter(
      lapsed: action != null && scheduler.isLapse(action),
      answersInSession: row.answersInSession,
    );
    await _apply(
      step,
      row,
      answers: row.answersInSession + (action == null ? 0 : 1),
      cursor: cursor,
      at: at,
    );
    await _dao.setCursor(session.id, cursor);
    // A card finishes learning with the last stage it takes part in; a
    // card at the cap stays new (BR-STUDY-053, UC-STUDY-001 A2b).
    if (kind == SessionKind.learning &&
        step is! LeaveAtCap &&
        !await _queue.hasPendingRows(session.id, cardId)) {
      await _required(
        _schedules.completeLearning(
          cardId: cardId,
          generation: session.generation,
          now: at,
        ),
        'finishing learning $cardId',
      );
    }
    await _progress(session, type, at);
    return const Ok(null);
  }

  /// What [step] does to [row] (spec §5.5).
  Future<void> _apply(
    RowStep step,
    StudyQueueItem row, {
    required int answers,
    required int cursor,
    required DateTime at,
  }) async {
    switch (step) {
      case Leave():
        await _queue.leave(row, answers: answers);
      case ComeBack(:final afterTurns):
        await _queue.keep(
          row,
          answers: answers,
          availableAt: cursor + afterTurns,
        );
      case LeaveAtCap():
        await _queue.leave(row, answers: answers);
        // Nothing turns the flag off (BR-STUDY-073, BR-CARD-009).
        await _required(
          _cards.setFlagged(cardIds: {row.cardId}, isFlagged: true, now: at),
          'flagging ${row.cardId}',
        );
      case StayAndEnroll():
        await _queue.keep(row, answers: answers);
        await _queue.enroll(row.sessionId, row.mode, row.round + 1, row.cardId);
      case LeaveAndEnroll():
        await _queue.leave(row, answers: answers);
        await _queue.enroll(row.sessionId, row.mode, row.round + 1, row.cardId);
    }
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
        await _build(session.id, mode, round);
      }
      if (mode != current) await _dao.setCurrentMode(session.id, mode.code);
      return;
    }
    await _dao.endSession(session.id, status: SessionStatus.completed, now: at);
  }

  /// Shuffles [round], unlike the round before it (BR-STUDY-061).
  Future<void> _build(String sessionId, StudyMode mode, int round) async {
    final previous = await _queue.cardsOf(sessionId, mode.code, round - 1);
    final cards = await _queue.cardsOf(sessionId, mode.code, round);
    await _queue.build(
      sessionId,
      mode.code,
      round,
      shuffledUnlike(cards, previous, _random),
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

/// A write the turn cannot go without. A refusal there means study and the
/// feature it calls disagree: a bug, which rolls the turn back (spec §7.3,
/// E3).
Future<void> _required<R extends Enum>(
  Future<Outcome<void, R>> write,
  String what,
) async {
  if (await write case Rejected(:final reason)) {
    throw StateError('$what refused: $reason');
  }
}

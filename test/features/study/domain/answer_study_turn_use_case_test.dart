import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 E2 and E3: what a failed write does to the turn and to the
// session (spec D9).

const _good = SelfAssessAnswer(Sm2Action.good);

/// The real srs writes, failing the next turn with [fault] once they are
/// done, so the turn's transaction has something to roll back.
final class _FaultySchedules implements ScheduleRepository {
  _FaultySchedules(this._schedules);

  final ScheduleRepository _schedules;
  Exception? fault;

  @override
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn) async {
    final recorded = await _schedules.recordTurn(turn);
    final pending = fault;
    fault = null;
    if (pending != null) throw pending;
    return recorded;
  }

  @override
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
  }) => _schedules.completeLearning(
    cardId: cardId,
    generation: generation,
    now: now,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A session store whose answer fails with [answerError], or is refused
/// when there is none, and whose close fails with [failError].
final class _BrokenSessions implements StudySessionRepository {
  _BrokenSessions({this.answerError, this.failError});

  final Failure? answerError;
  final Failure? failError;
  final failed = <String>[];

  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) async {
    final error = answerError;
    if (error != null) throw error;
    return const Rejected(StudyRejection.notCurrentCard);
  }

  @override
  Future<void> failSession({required String sessionId, DateTime? now}) async {
    failed.add(sessionId);
    final error = failError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late _FaultySchedules schedules;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepository sessions;
  late AnswerStudyTurnUseCase answerTurn;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    schedules = _FaultySchedules(ScheduleRepositoryImpl(db, now: () => now));
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now, schedules: schedules);
    answerTurn = AnswerStudyTurnUseCase(sessions);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<Outcome<TurnResult, StudyRejection>> turn(
    String sessionId,
    StudyAnswer answer,
  ) async => answerTurn(
    sessionId: sessionId,
    cardId: (await servedCard(db, sessionId))!,
    answer: answer,
  );

  Future<void> answer(String sessionId, StudyAnswer answer) async =>
      expect(await turn(sessionId, answer), isA<Ok<void, StudyRejection>>());

  /// A learning session on [count] new cards `c1`… of an sm2 tree, past its
  /// browse stage.
  Future<String> selfAssessing(int count) async {
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    for (var i = 1; i <= count; i++) {
      await insertCard(db, id: 'c$i', deckId: leaf.id);
    }
    final opened = await entries.openLearningSession(deckId: leaf.id);
    final id = (opened as Ok<String, StudyRejection>).value;
    for (var i = 0; i < count; i++) {
      await answer(id, const AdvanceAnswer());
    }
    return id;
  }

  Future<int> logCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  test(
    'a busy database writes nothing and keeps the session open; the retry '
    'records the turn once (IT-CONT-011, UC-STUDY-001 E2, BR-STUDY-004)',
    () async {
      final id = await selfAssessing(1);
      schedules.fault = sqlite3.SqliteException(
        extendedResultCode: 5,
        message: 'database is locked',
      );

      await expectLater(turn(id, _good), throwsA(isA<DatabaseLockedFailure>()));

      final session = await sessionOf(db, id);
      expect(session.read<String>('status'), 'in_progress');
      expect(session.read<int>('cursor'), 1);
      expect(await logCount(), 0);
      expect((await scheduleRowOf(db, 'c1')).data['learned_at'], isNull);

      await answer(id, _good);

      expect(await turnKindsOf(db, 'c1'), ['learning']);
      expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    },
  );

  test('a recall timeout that met a busy database is sent again and recorded '
      'once, with its reason (BR-STUDY-033, UC-STUDY-001 E2)', () async {
    final leaf = await insertFiveDue(
      db,
      DeckRepositoryImpl(db, now: () => now),
    );
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    schedules.fault = sqlite3.SqliteException(
      extendedResultCode: 5,
      message: 'database is locked',
    );
    const timedOut = RecallAnswer(RecallOutcome.timedOut);

    await expectLater(
      turn(id, timedOut),
      throwsA(isA<DatabaseLockedFailure>()),
    );
    expect(await logCount(), 0);

    expect(
      await turn(id, timedOut),
      isA<Ok<TurnResult, StudyRejection>>().having(
        (ok) => ok.value.isCorrect,
        'isCorrect',
        isFalse,
      ),
    );
    final log = await db
        .customSelect('SELECT "action", outcome_reason FROM review_log')
        .getSingle();
    expect(
      (log.read<String>('action'), log.read<String>('outcome_reason')),
      ('forgotten', 'timeout'),
    );
  });

  test('a fatal error rolls the turn back and closes the session as failed; '
      'the turns before it stay (IT-CONT-012, UC-STUDY-001 E3, BR-STUDY-018, '
      'BR-STUDY-019)', () async {
    final id = await selfAssessing(3);
    await answer(id, _good);
    await answer(id, _good);
    final third = (await servedCard(db, id))!;
    schedules.fault = sqlite3.SqliteException(
      extendedResultCode: 11,
      message: 'database disk image is malformed',
    );

    await expectLater(turn(id, _good), throwsA(isA<UnknownDatabaseFailure>()));

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'failed');
    expect(session.read<String>('end_reason'), 'persistence_error');
    expect(await logCount(), 2);
    expect(await turnKindsOf(db, third), isEmpty);
    expect((await scheduleRowOf(db, third)).data['learned_at'], isNull);
  });

  test('when closing the session fails too, the turn keeps its own failure '
      '(spec §8.3)', () async {
    final sessions = _BrokenSessions(
      answerError: const UnknownDatabaseFailure(cause: 'disk'),
      failError: const DatabaseLockedFailure(cause: 'busy'),
    );

    await expectLater(
      AnswerStudyTurnUseCase(sessions)(
        sessionId: 's1',
        cardId: 'c1',
        answer: const AdvanceAnswer(),
      ),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
    expect(sessions.failed, ['s1']);
  });

  test('a refusal comes back as it is and leaves the session open', () async {
    final sessions = _BrokenSessions();

    final result = await AnswerStudyTurnUseCase(sessions)(
      sessionId: 's1',
      cardId: 'c1',
      answer: const AdvanceAnswer(),
    );

    expect(
      (result as Rejected<void, StudyRejection>).reason,
      StudyRejection.notCurrentCard,
    );
    expect(sessions.failed, isEmpty);
  });
}

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 A3 and A3b: leaving a session, Continue, and the sessions of
// earlier days.

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<void, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  var clock = DateTime(2026, 9, 24, 9);
  setUp(() {
    clock = DateTime(2026, 9, 24, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    entries = studyEntryRepository(db, () => clock);
    sessions = studySessionRepository(db, () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// A learning session on the new cards [cardIds] of a fresh [type] tree.
  Future<(DeckEntity, String)> learning(
    List<String> cardIds, [
    SchedulerType type = SchedulerType.eightBox,
  ]) async {
    final root = await decks.root('Korean', type);
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final id in cardIds) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final opened = await entries.openLearningSession(deckId: leaf.id);
    return (leaf, (opened as Ok<String, StudyRejection>).value);
  }

  Future<void> answer(String sessionId, StudyAnswer answer) async => expect(
    await sessions.answerTurn(
      sessionId: sessionId,
      cardId: (await servedCard(db, sessionId))!,
      answer: answer,
    ),
    isA<Ok<void, StudyRejection>>(),
  );

  Future<List<Map<String, Object?>>> queueRows(String sessionId) async => [
    for (final row
        in await db
            .customSelect(
              'SELECT * FROM study_queue_items WHERE session_id = ?'
              ' ORDER BY mode, round, position',
              variables: [Variable(sessionId)],
            )
            .get())
      row.data,
  ];

  /// Spec D12 settles the sessions a build before the Trash left open.
  Future<void> deleteCards(Set<String> cardIds) => hardDeleteCards(db, cardIds);

  test('leaving ends the session as user_exit and keeps its turns; a '
      'session that has ended cannot be left again (BR-STUDY-014, '
      'BR-STUDY-019; UC-STUDY-001 A3)', () async {
    final (_, id) = await learning(['c1'], SchedulerType.sm2);
    await answer(id, const AdvanceAnswer());
    await answer(id, const SelfAssessAnswer(Sm2Action.again));

    expect(
      await sessions.abandonSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'abandoned');
    expect(session.read<String>('end_reason'), 'user_exit');
    expect(session.read<DateTime>('ended_at'), clock);
    expect(await turnKindsOf(db, 'c1'), ['learning']);
    expect(
      await sessions.abandonSession(sessionId: id),
      _refusedWith(StudyRejection.sessionClosed),
    );
  });

  test('Continue on the same day finds the session where it stopped: the '
      'same card, cursor and queue (IT-CONT-001; UC-STUDY-001 A3b)', () async {
    final (_, id) = await learning(['a', 'b', 'c']);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    final served = await servedCard(db, id);
    final rows = await queueRows(id);
    clock = DateTime(2026, 9, 24, 22);

    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );

    expect(await servedCard(db, id), served);
    expect((await sessionOf(db, id)).read<int>('cursor'), 2);
    expect(await queueRows(id), rows);
  });

  test('a card added after the session opened never joins its queue '
      '(IT-CONT-006)', () async {
    final (leaf, id) = await learning(['a', 'b']);
    await insertCard(db, id: 'late', deckId: leaf.id, back: 'late');
    await sessions.resumeSession(sessionId: id);

    while ((await sessionOf(db, id)).read<String>('status') == 'in_progress') {
      await answerServed(db, sessions, id, right: true);
    }

    final lateRows = await db
        .customSelect("SELECT 1 FROM study_queue_items WHERE card_id = 'late'")
        .get();
    expect(lateRows, isEmpty);
    expect(await turnKindsOf(db, 'late'), isEmpty);
    expect((await scheduleRowOf(db, 'late')).data['learned_at'], isNull);
  });

  test('a session from an earlier local day is closed as interrupted and '
      'refused as sessionExpired; its turns stay (IT-CONT-003, '
      'BR-STUDY-072)', () async {
    final (_, id) = await learning(['c1'], SchedulerType.sm2);
    await answer(id, const AdvanceAnswer());
    await answer(id, const SelfAssessAnswer(Sm2Action.again));
    clock = DateTime(2026, 9, 25, 0, 30);

    expect(
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.sessionExpired),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'abandoned');
    expect(session.read<String>('end_reason'), 'interrupted');
    expect(session.read<DateTime>('ended_at'), clock);
    expect(await turnKindsOf(db, 'c1'), ['learning']);
    expect(
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.sessionClosed),
    );
  });

  test('Continue on a session whose root was reset since invalidates it '
      '(BR-STUDY-017)', () async {
    final (_, id) = await learning(['c1']);
    final rootId = (await sessionOf(db, id)).read<String>('root_id');
    await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
      rootId,
    ]);
    await db.customStatement('UPDATE card_schedule SET generation = 2');

    expect(
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.staleGeneration),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'stale_generation');
  });

  test('when the cards left in the current stage were deleted, Continue '
      'moves on to the next stage, and a session with nothing left '
      'completes (spec D12, BR-STUDY-013)', () async {
    final (_, id) = await learning(['a', 'b', 'c']);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    final last = (await servedCard(db, id))!;
    await deleteCards({last});

    expect(await servedCard(db, id), isNull);
    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );
    expect((await sessionOf(db, id)).read<String>('current_mode'), 'match');

    await deleteCards({'a', 'b', 'c'}..remove(last));
    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );
    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'completed');
    expect(session.data['end_reason'], isNull);
  });

  test('Continue or leaving a session whose deck went to the Trash is '
      'sessionClosed: the delete ended it as content_deleted (IT-CONT-007, '
      'BR-TRASH-004)', () async {
    final (leaf, id) = await learning(['c1']);
    expect(
      await decks.deleteDeck(deckId: leaf.id),
      isA<Ok<String, DeckRejection>>(),
    );

    expect(
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.sessionClosed),
    );
    expect(
      await sessions.abandonSession(sessionId: id),
      _refusedWith(StudyRejection.sessionClosed),
    );
  });

  test('when the app starts, the open session of an earlier day closes as '
      "interrupted, and one of today's stays open (BR-STUDY-072; "
      'UC-STUDY-001 A3b)', () async {
    final (leaf, earlier) = await learning(['c1']);
    clock = DateTime(2026, 9, 25, 8);

    await sessions.abandonStaleSessions();

    final stale = await sessionOf(db, earlier);
    expect(stale.read<String>('status'), 'abandoned');
    expect(stale.read<String>('end_reason'), 'interrupted');
    expect(stale.read<DateTime>('ended_at'), clock);

    final opened = await entries.openLearningSession(deckId: leaf.id);
    final today = (opened as Ok<String, StudyRejection>).value;
    await sessions.abandonStaleSessions();
    expect((await sessionOf(db, today)).read<String>('status'), 'in_progress');
  });

  test('when the last cards of a round were deleted after a wrong answer, '
      'Continue builds the next round and serves it (spec D7, D12)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, day) in [('a', 20), ('b', 21), ('c', 22)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        back: 'meaning $id',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
        box: 2,
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    await answerServed(db, sessions, id, right: false);
    await deleteCards({'b', 'c'});
    expect(await servedCard(db, id), isNull);

    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );

    expect(await servedCard(db, id), 'a');
    expect(await queueOf(db, id, 'recall', round: 2), ['a']);
    expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');
  });

  test('an answer on a card deleted after it was served is refused as '
      'notCurrentCard and writes nothing; the next card is served '
      '(spec §7.3 step 2)', () async {
    final (_, id) = await learning(['a', 'b', 'c']);
    final served = (await servedCard(db, id))!;
    await deleteCards({served});

    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: served,
        answer: const AdvanceAnswer(),
      ),
      _refusedWith(StudyRejection.notCurrentCard),
    );

    expect((await sessionOf(db, id)).read<int>('cursor'), 0);
    expect(await servedCard(db, id), isNot(served));
  });

  test('a session keeps taking answers after midnight: only Continue and the '
      'app start close a session of an earlier day (BR-STUDY-072)', () async {
    clock = DateTime(2026, 9, 24, 23, 50);
    final (_, id) = await learning(['a', 'b']);
    await answer(id, const AdvanceAnswer());
    clock = DateTime(2026, 9, 25, 0, 10);

    await answer(id, const AdvanceAnswer());

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'in_progress');
    expect(session.read<int>('cursor'), 2);
  });

  test('a sub-deck moved into another tree whose root is then reset ends the '
      'session holding its cards, so no answer is refused for good '
      '(BR-STUDY-015, BR-STUDY-017, BR-SRS-006)', () async {
    final (leaf, id) = await learning(['a', 'b']);
    final other = await decks.root('Other');
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    expect(
      await decks.moveDeck(deckId: leaf.id, newParentId: other.id),
      isA<Ok<void, DeckRejection>>(),
    );

    expect(
      await ScheduleRepositoryImpl(
        db,
        now: () => clock,
      ).resetLearning(rootDeckId: other.id),
      isA<Ok<void, SrsRejection>>(),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_reset');
    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: 'a',
        answer: const AdvanceAnswer(),
      ),
      _refusedWith(StudyRejection.sessionClosed),
    );
    final entry = await entries.watchEntry(deckId: leaf.id, now: clock).first;
    expect(entry!.resumableSessionId, isNull);
  });
}

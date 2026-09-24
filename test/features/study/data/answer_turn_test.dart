import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 6–13 on sm2 decks: browse, self_assess and the errors
// every answer checks first.

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
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// A learning session on [count] new cards `c1`… of an sm2 tree.
  Future<(String, String)> learning(int count) async {
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    for (var i = 1; i <= count; i++) {
      await insertCard(db, id: 'c$i', deckId: leaf.id, back: 'meaning $i');
    }
    final opened = await entries.openLearningSession(deckId: leaf.id);
    return (root.id, (opened as Ok<String, StudyRejection>).value);
  }

  Future<void> answer(String sessionId, StudyAnswer answer) async {
    final cardId = await servedCard(db, sessionId);
    expect(
      await sessions.answerTurn(
        sessionId: sessionId,
        cardId: cardId!,
        answer: answer,
      ),
      isA<Ok<void, StudyRejection>>(),
      reason: 'answer on $cardId',
    );
  }

  Future<void> browseAll(String sessionId, int count) async {
    for (var i = 0; i < count; i++) {
      await answer(sessionId, const AdvanceAnswer());
    }
  }

  Future<int> logCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  test('browse moves on without a turn: the row leaves the queue and the '
      'cursor moves, with no log and no schedule change (BR-MODE-005, '
      'BR-STUDY-007; IT-LEARN-003)', () async {
    final (_, id) = await learning(2);
    final first = await servedCard(db, id);

    await answer(id, const AdvanceAnswer());

    expect((await sessionOf(db, id)).read<int>('cursor'), 1);
    expect(await servedCard(db, id), isNot(first));
    expect(await logCount(), 0);
    expect((await scheduleRowOf(db, first!)).data['last_answered_at'], isNull);
  });

  test('the sm2 chain runs browse, then self_assess; a card passing its '
      'last stage finishes learning, and the first one locks the scheduler '
      '(IT-LEARN-002, IT-LEARN-010, BR-STUDY-053, BR-SRS-003)', () async {
    final (rootId, id) = await learning(2);
    await browseAll(id, 2);
    expect(
      (await sessionOf(db, id)).read<String>('current_mode'),
      'self_assess',
    );
    final first = await servedCard(db, id);

    await answer(id, const SelfAssessAnswer(Sm2Action.good));

    final schedule = await scheduleRowOf(db, first!);
    expect(schedule.read<DateTime>('learned_at'), now);
    expect(schedule.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    expect(schedule.read<int>('interval_days'), 1);
    expect(await turnKindsOf(db, first), ['learning']);
    expect(
      (await deckRowOf(db, rootId)).read<DateTime>('first_answered_at'),
      now,
    );
    expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');

    await answer(id, const SelfAssessAnswer(Sm2Action.easy));

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'completed');
    expect(session.data['end_reason'], isNull);
    expect(session.read<DateTime>('ended_at'), now);
  });

  test('a forgotten card comes back after three other cards, then last when '
      'fewer remain, and at the cap it leaves flagged and still new '
      '(IT-LEARN-009, BR-STUDY-005, BR-STUDY-073, BR-CARD-009)', () async {
    final (_, id) = await learning(5);
    await browseAll(id, 5);
    final order = await queueOf(db, id, 'self_assess');
    const again = SelfAssessAnswer(Sm2Action.again);
    const good = SelfAssessAnswer(Sm2Action.good);

    await answer(id, again);
    final served = <String?>[];
    for (var i = 0; i < 3; i++) {
      served.add(await servedCard(db, id));
      await answer(id, good);
    }
    expect(served, order.sublist(1, 4));
    expect(await servedCard(db, id), order[0]);
    await answer(id, again);
    expect(await servedCard(db, id), order[4]);
    await answer(id, good);
    for (var turn = 3; turn <= 4; turn++) {
      expect(await servedCard(db, id), order[0], reason: 'turn $turn');
      await answer(id, again);
    }

    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    final capped = await db
        .customSelect(
          'SELECT c.is_flagged, s.learned_at FROM card c '
          'JOIN card_schedule s ON s.card_id = c.id WHERE c.id = ?',
          variables: [Variable(order[0])],
        )
        .getSingle();
    expect(capped.read<int>('is_flagged'), 1);
    expect(capped.data['learned_at'], isNull);
    expect(await turnKindsOf(db, order[0]), [
      'learning',
      'relearning',
      'relearning',
      'relearning',
    ]);
    for (final other in order.sublist(1)) {
      expect((await scheduleRowOf(db, other)).data['learned_at'], isNotNull);
    }
  });

  test('in a review the first turn is scheduled and moves the schedule; a '
      'forgotten card comes back as relearning, which keeps it, and every '
      'turn carries its row\'s direction (IT-REVIEW-003, IT-REVIEW-005, '
      'BR-STUDY-023, BR-SRS-016, BR-SRS-017, BR-MODE-016)', () async {
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.selfAssess,
      direction: DirectionChoice.koreanToMeaning,
    );
    final id = (opened as Ok<String, StudyRejection>).value;

    await answer(id, const SelfAssessAnswer(Sm2Action.again));
    final afterLapse = await scheduleRowOf(db, 'a');
    await answer(id, const SelfAssessAnswer(Sm2Action.good));
    await answer(id, const SelfAssessAnswer(Sm2Action.good));

    expect(afterLapse.read<int>('lapse_count'), 1);
    expect(afterLapse.read<int>('repetitions'), 0);
    expect(afterLapse.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    final relearned = await scheduleRowOf(db, 'a');
    expect(relearned.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    expect(relearned.read<int>('answer_count'), 1);
    expect(await turnKindsOf(db, 'a'), ['scheduled', 'relearning']);
    expect(await turnKindsOf(db, 'b'), ['scheduled']);
    final directions = await db
        .customSelect('SELECT DISTINCT direction FROM review_log')
        .get();
    expect(
      [for (final row in directions) row.read<String>('direction')],
      ['korean_to_meaning'],
    );
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
  });

  test(
    'an answer from a session whose root was reset since is refused, '
    'writes no turn and ends the session (BR-STUDY-017, IT-CONT-010)',
    () async {
      final (rootId, id) = await learning(1);
      await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
        rootId,
      ]);
      await db.customStatement('UPDATE card_schedule SET generation = 2');
      final card = await servedCard(db, id);

      expect(
        await sessions.answerTurn(
          sessionId: id,
          cardId: card!,
          answer: const AdvanceAnswer(),
        ),
        _refusedWith(StudyRejection.staleGeneration),
      );

      final session = await sessionOf(db, id);
      expect(session.read<String>('status'), 'invalidated');
      expect(session.read<String>('end_reason'), 'stale_generation');
      expect(session.read<DateTime>('ended_at'), now);
      expect(session.read<int>('cursor'), 0);
      expect(await logCount(), 0);
    },
  );

  test('a second tap on a card already answered records nothing '
      '(BR-STUDY-004, BR-STUDY-042)', () async {
    final (_, id) = await learning(2);
    await browseAll(id, 2);
    final card = await servedCard(db, id);
    await answer(id, const SelfAssessAnswer(Sm2Action.good));

    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: card!,
        answer: const SelfAssessAnswer(Sm2Action.good),
      ),
      _refusedWith(StudyRejection.notCurrentCard),
    );
    expect(await logCount(), 1);
  });

  test('an answer of another mode, or an action the algorithm lacks, is '
      'refused and writes nothing (BR-MODE-011, BR-STUDY-009)', () async {
    final (_, id) = await learning(1);
    final card = (await servedCard(db, id))!;
    final before = await totalChanges(db);

    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: card,
        answer: const SelfAssessAnswer(Sm2Action.good),
      ),
      _refusedWith(StudyRejection.answerDoesNotFitMode),
    );
    await answer(id, const AdvanceAnswer());
    final atSelfAssess = await totalChanges(db);
    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: card,
        answer: const SelfAssessAnswer(EightBoxAction.remembered),
      ),
      _refusedWith(StudyRejection.unsupportedAction),
    );
    expect(atSelfAssess, greaterThan(before));
    expect(await totalChanges(db), atSelfAssess);
  });

  test('a session that ended, or one that is gone, takes no answer', () async {
    final (_, id) = await learning(1);
    final card = (await servedCard(db, id))!;
    await db.customStatement(
      "UPDATE study_session SET status = 'abandoned', "
      "end_reason = 'user_exit', ended_at = 0",
    );

    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: card,
        answer: const AdvanceAnswer(),
      ),
      _refusedWith(StudyRejection.sessionClosed),
    );
    expect(
      await sessions.answerTurn(
        sessionId: 'missing',
        cardId: card,
        answer: const AdvanceAnswer(),
      ),
      _refusedWith(StudyRejection.notFound),
    );
  });
}

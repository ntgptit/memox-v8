import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/srs_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl repo;
  final now = DateTime(2026, 9, 23);
  setUp(() {
    db = openTestDatabase();
    repo = ScheduleRepositoryImpl(db, now: () => now);
  });
  tearDown(() => db.close());

  test('initializeCards writes the start values of the root scheduler at the root generation, for every card (BR-CARD-004)', () async {
    await insertStudyTree(db, 'r', scheduler: 'sm2');
    await db.customStatement("UPDATE deck SET generation = 3 WHERE id = 'r'");
    await insertBareCard(db, 'new', 'r-leaf');
    await insertBareCard(db, 'next', 'r-leaf');

    await repo.initializeCards(deckId: 'r-leaf', cardIds: ['new', 'next']);

    for (final cardId in ['new', 'next']) {
      expectStartValues(
        await scheduleRowOf(db, cardId),
        scheduler: 'sm2',
        generation: 3,
      );
    }
  });

  test('initializeCards reads the root once, whatever the number of cards (BR-TRANSFER-004)', () async {
    final counter = SelectCounter();
    final counted = openTestDatabase(interceptor: counter);
    addTearDown(counted.close);
    await insertStudyTree(counted, 'r');
    for (final cardId in ['n1', 'n2', 'n3']) {
      await insertBareCard(counted, cardId, 'r-leaf');
    }
    counter.selects = 0;

    await ScheduleRepositoryImpl(counted)
        .initializeCards(deckId: 'r-leaf', cardIds: ['n1', 'n2', 'n3']);

    expect(counter.selects, 1);
  });

  test('initializeCards for a deck that is gone throws', () async {
    await expectLater(
      repo.initializeCards(deckId: 'missing', cardIds: ['x']),
      throwsStateError,
    );
  });

  test('resetLearning bumps generation and recreates card_schedule', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);

    await repo.resetLearning(rootDeckId: rootId);

    expect((await deckRowOf(db, rootId)).read<int>('generation'), 2);
    expectStartValues(
      await scheduleRowOf(db, cardId),
      scheduler: 'eight_box',
      generation: 2,
    );
  });

  test('resetLearning of an sm2 tree writes sm2 start values', () async {
    final (rootId, cardId, _) = await insertStudyTree(
      db,
      'r',
      scheduler: 'sm2',
    );
    await repo.completeLearning(cardId: cardId, generation: 1);

    await repo.resetLearning(rootDeckId: rootId);

    expectStartValues(
      await scheduleRowOf(db, cardId),
      scheduler: 'sm2',
      generation: 2,
    );
  });

  test('resetLearning unlocks the scheduler and closes the open sessions (BR-SRS-024, BR-STUDY-015)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);

    await repo.resetLearning(rootDeckId: rootId);

    expect((await deckRowOf(db, rootId)).data['first_answered_at'], isNull);
    final session = await sessionRowOf(db, sessionId);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_reset');
    expect(session.data['ended_at'], isNotNull);
  });

  test('resetLearning of a sub-deck is rejected with notARootDeck and writes nothing', () async {
    await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    final result = await repo.resetLearning(rootDeckId: 'r-leaf');

    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.notARootDeck,
    );
    expect(await totalChanges(db), before);
  });

  test(
    'changeScheduler before the first review is allowed and keeps generation',
    () async {
      final (rootId, _, _) = await insertStudyTree(db, 'r');
      final result = await repo.changeScheduler(
        rootDeckId: rootId,
        newType: SchedulerType.sm2,
      );
      expect(result, isA<Ok<void, SrsRejection>>());

      final root = await deckRowOf(db, rootId);
      expect(root.read<String>('scheduler_type'), 'sm2');
      expect(
        root.read<int>('generation'),
        1,
        reason: 'BR-SRS-002: a change is not a reset',
      );
    },
  );

  test('changeScheduler starts every card of the tree over under the new scheduler (BR-SRS-004)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    final deepCardId = await insertDeepCard(db, rootId);

    await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);

    expectStartValues(
      await scheduleRowOf(db, cardId),
      scheduler: 'sm2',
      generation: 1,
    );
    expectStartValues(
      await scheduleRowOf(db, deepCardId),
      scheduler: 'sm2',
      generation: 1,
    );
  });

  test(
    'changeScheduler closes the open sessions of the tree (BR-STUDY-016)',
    () async {
      final (rootId, _, sessionId) = await insertStudyTree(db, 'r');

      await repo.changeScheduler(
        rootDeckId: rootId,
        newType: SchedulerType.sm2,
      );

      final session = await sessionRowOf(db, sessionId);
      expect(session.read<String>('status'), 'invalidated');
      expect(session.read<String>('end_reason'), 'scheduler_changed');
      expect(session.data['ended_at'], isNotNull);
    },
  );

  test('a reset closes an open session of another tree that holds a card '
      'moved into this one (BR-STUDY-015, BR-SRS-006)', () async {
    await insertStudyTree(db, 'r');
    await insertStudyTree(db, 'other');
    await moveLeafWithQueuedCard(db, 'r', 'other');

    await repo.resetLearning(rootDeckId: 'other');

    final session = await sessionRowOf(db, 'r-session');
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_reset');
  });

  test('a scheduler change closes an open session of another tree that holds '
      'a card moved into this one (BR-STUDY-016, BR-SRS-006)', () async {
    await insertStudyTree(db, 'r');
    await insertStudyTree(db, 'other');
    await moveLeafWithQueuedCard(db, 'r', 'other');

    await repo.changeScheduler(rootDeckId: 'other', newType: SchedulerType.sm2);

    final session = await sessionRowOf(db, 'r-session');
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_changed');
  });

  test('changeScheduler leaves other trees alone', () async {
    final (rootId, _, _) = await insertStudyTree(db, 'r');
    final (_, otherCardId, otherSessionId) = await insertStudyTree(db, 'other');

    await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);

    expectStartValues(
      await scheduleRowOf(db, otherCardId),
      scheduler: 'eight_box',
      generation: 1,
    );
    expect(
      (await sessionRowOf(db, otherSessionId)).read<String>('status'),
      'in_progress',
    );
  });

  test('changeScheduler to the scheduler the root runs writes nothing (UC-DECK-002 A4)', () async {
    final (rootId, _, _) = await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    final result = await repo.changeScheduler(
      rootDeckId: rootId,
      newType: SchedulerType.eightBox,
    );

    expect(result, isA<Ok<void, SrsRejection>>());
    expect(await totalChanges(db), before);
  });

  test('the scheduler the root runs is a no-op on a locked tree too, not a rejection', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final before = await totalChanges(db);

    final result = await repo.changeScheduler(
      rootDeckId: rootId,
      newType: SchedulerType.eightBox,
    );

    expect(result, isA<Ok<void, SrsRejection>>());
    expect(await totalChanges(db), before);
  });

  test('changeScheduler once a card finished learning is rejected (locked, '
      'BR-SRS-003)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final before = await totalChanges(db);

    final result = await repo.changeScheduler(
      rootDeckId: rootId,
      newType: SchedulerType.sm2,
    );
    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.schedulerLocked,
    );
    expect(await totalChanges(db), before);
  });

  test('changeScheduler of a sub-deck is rejected with notARootDeck and writes nothing', () async {
    await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    final result = await repo.changeScheduler(
      rootDeckId: 'r-leaf',
      newType: SchedulerType.sm2,
    );

    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.notARootDeck,
    );
    expect(await totalChanges(db), before);
  });

  test('changeScheduler of a missing deck is notFound', () async {
    final result = await repo.changeScheduler(
      rootDeckId: 'missing',
      newType: SchedulerType.sm2,
    );
    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.notFound,
    );
  });

  test('changeScheduler and resetLearning do not reach a root in the Trash (spec §8)', () async {
    // The whole tree in one batch, as deleting a deck will leave it.
    await insertStudyTree(db, 'r');
    await trashDeckRows(db, 'r');
    final before = await totalChanges(db);
    final isNotFound = isA<Rejected<void, SrsRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      SrsRejection.notFound,
    );

    expect(
      await repo.changeScheduler(rootDeckId: 'r', newType: SchedulerType.sm2),
      isNotFound,
    );
    expect(await repo.resetLearning(rootDeckId: 'r'), isNotFound);
    expect(await totalChanges(db), before);
  });
}

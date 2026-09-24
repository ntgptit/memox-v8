import 'package:drift/drift.dart'
    show QueryExecutor, QueryInterceptor, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';

import '../../../support/srs_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SRS-001: reset learning progress, and what its confirmation shows.

/// Fails the statement that writes a reset's new schedule rows, after the
/// root and the old rows already changed in the same transaction.
final class _FailingScheduleInsert extends QueryInterceptor {
  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.startsWith('INSERT INTO card_schedule')) {
      throw SqliteException(
        extendedResultCode: 13,
        message: 'database or disk is full',
      );
    }
    return super.runInsert(executor, statement, args);
  }
}

Matcher _refusedWith<T>(SrsRejection reason) => isA<Rejected<T, SrsRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl repo;
  final now = DateTime(2026, 9, 24);
  setUp(() {
    db = openTestDatabase();
    repo = ScheduleRepositoryImpl(db, now: () => now);
  });
  tearDown(() => db.close());

  for (final (from, to, learn) in <(String, SchedulerType, Object)>[
    ('sm2', SchedulerType.eightBox, Sm2Action.good),
    ('eight_box', SchedulerType.sm2, EightBoxAction.remembered),
  ]) {
    test('a reset switches a locked $from tree to ${to.code} at its start '
        'values (UC-SRS-001 steps 3 and 5)', () async {
      final (rootId, cardId, sessionId) = await insertStudyTree(
        db,
        'r',
        scheduler: from,
      );
      await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: learn,
      );
      expect(
        (await deckRowOf(db, rootId)).data['first_answered_at'],
        isNotNull,
      );

      final result = await repo.resetLearning(
        rootDeckId: rootId,
        schedulerType: to,
      );

      expect(result, isA<Ok<void, SrsRejection>>());
      final root = await deckRowOf(db, rootId);
      expect(root.read<String>('scheduler_type'), to.code);
      expect(root.read<int>('scheduler_version'), schedulerFor(to).version);
      expect(root.data['scheduler_config'], isNull);
      expect(root.read<int>('generation'), 2);
      expect(root.data['first_answered_at'], isNull);
      expectStartValues(
        await scheduleRowOf(db, cardId),
        scheduler: to.code,
        generation: 2,
      );
    });
  }

  test('a reset that names the scheduler the root runs keeps it '
      '(UC-SRS-001 A1)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(
      db,
      'r',
      scheduler: 'sm2',
    );
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: Sm2Action.good,
    );

    final result = await repo.resetLearning(
      rootDeckId: rootId,
      schedulerType: SchedulerType.sm2,
    );

    expect(result, isA<Ok<void, SrsRejection>>());
    final root = await deckRowOf(db, rootId);
    expect(root.read<String>('scheduler_type'), 'sm2');
    expect(root.read<int>('scheduler_version'), 1);
    expect(root.read<int>('generation'), 2);
    expectStartValues(
      await scheduleRowOf(db, cardId),
      scheduler: 'sm2',
      generation: 2,
    );
  });

  test('a reset while a session is open closes it, refuses its next answer '
      'and keeps the answers given before (IT-CONT-009, host half)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    await repo.resetLearning(rootDeckId: rootId);
    final lateAnswer = await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    final session = await sessionRowOf(db, sessionId);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_reset');
    expect(lateAnswer, _refusedWith<void>(SrsRejection.staleGeneration));
    final logs = await db
        .customSelect(
          'SELECT generation FROM review_log WHERE card_id = ?',
          variables: [Variable(cardId)],
        )
        .get();
    expect([for (final log in logs) log.read<int>('generation')], [1]);
  });

  test('a reset keeps the tree, the cards and their tags (BR-SRS-021)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await insertDeepCard(db, rootId);
    await db.customStatement(
      'INSERT INTO tags (id, name, name_folded, created_at) '
      "VALUES ('t', 'Fruit', 'fruit', 0)",
    );
    await db.customStatement(
      "INSERT INTO card_tags (card_id, tag_id) VALUES (?, 't')",
      [cardId],
    );
    Future<List<Map<String, Object?>>> content() async => [
      for (final row
          in await db
              .customSelect(
                'SELECT d.id, d.name, d.parent_id, d.root_id, d.depth, '
                'd.content_type, d.sibling_position, c.id AS card_id, c.front, '
                'c.back, t.tag_id FROM deck d '
                'LEFT JOIN card c ON c.deck_id = d.id '
                'LEFT JOIN card_tags t ON t.card_id = c.id ORDER BY d.id, c.id',
              )
              .get())
        row.data,
    ];
    final before = await content();

    await repo.resetLearning(
      rootDeckId: rootId,
      schedulerType: SchedulerType.sm2,
    );

    expect(await content(), before);
  });

  test('a reset that fails midway leaves the whole tree as it was '
      '(UC-SRS-001 E1, BR-SRS-027)', () async {
    final failing = openTestDatabase(interceptor: _FailingScheduleInsert());
    addTearDown(failing.close);
    final broken = ScheduleRepositoryImpl(failing, now: () => now);
    final (rootId, cardId, sessionId) = await insertStudyTree(failing, 'r');
    await broken.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    await expectLater(
      broken.resetLearning(
        rootDeckId: rootId,
        schedulerType: SchedulerType.sm2,
      ),
      throwsA(isA<UnknownDatabaseFailure>()),
    );

    final root = await deckRowOf(failing, rootId);
    expect(root.read<String>('scheduler_type'), 'eight_box');
    expect(root.read<int>('generation'), 1);
    expect(root.data['first_answered_at'], isNotNull);
    final schedule = await scheduleRowOf(failing, cardId);
    expect(schedule.read<int>('current_box'), 2);
    expect(schedule.data['learned_at'], isNotNull);
    expect(
      (await sessionRowOf(failing, sessionId)).read<String>('status'),
      'in_progress',
    );
  });

  test('a reset of a root that does not exist is notFound and writes '
      'nothing', () async {
    await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    final result = await repo.resetLearning(
      rootDeckId: 'missing',
      schedulerType: SchedulerType.sm2,
    );

    expect(result, _refusedWith<void>(SrsRejection.notFound));
    expect(await totalChanges(db), before);
  });

  test(
    'a reset leaves every other tree as it was (UC-SRS-001 step 5)',
    () async {
      final (rootId, cardId, sessionId) = await insertStudyTree(db, 'a');
      final (otherId, otherCardId, otherSessionId) = await insertStudyTree(
        db,
        'b',
      );
      for (final (card, session) in [
        (cardId, sessionId),
        (otherCardId, otherSessionId),
      ]) {
        await repo.recordReview(
          cardId: card,
          sessionId: session,
          action: EightBoxAction.remembered,
        );
      }

      await repo.resetLearning(
        rootDeckId: rootId,
        schedulerType: SchedulerType.sm2,
      );

      final other = await deckRowOf(db, otherId);
      expect(other.read<String>('scheduler_type'), 'eight_box');
      expect(other.read<int>('generation'), 1);
      expect(other.data['first_answered_at'], isNotNull);
      expect(
        (await scheduleRowOf(db, otherCardId)).read<int>('current_box'),
        2,
      );
      expect(
        (await sessionRowOf(db, otherSessionId)).read<String>('status'),
        'in_progress',
      );
    },
  );

  Future<ResetLearningSummary> summaryOf(String rootId) async =>
      switch (await repo.resetSummary(rootDeckId: rootId)) {
        Ok(:final value) => value,
        Rejected(:final reason) => fail('resetSummary refused: $reason'),
      };

  test('the summary of a tree nobody has studied has nothing to lose '
      '(UC-SRS-001 A2)', () async {
    final (rootId, _, sessionId) = await insertStudyTree(
      db,
      'r',
      scheduler: 'sm2',
    );
    await db.customStatement('DELETE FROM study_session WHERE id = ?', [
      sessionId,
    ]);

    final summary = await summaryOf(rootId);

    expect(summary.schedulerType, SchedulerType.sm2);
    expect(summary.isSchedulerLocked, isFalse);
    expect(summary.cardCount, 1);
    expect(summary.learnedCardCount, 0);
    expect(summary.openSessionCount, 0);
    expect(summary.hasProgressToLose, isFalse);
  });

  test('the summary counts the learned cards and the open sessions of the '
      'whole tree, outside the Trash (UC-SRS-001 step 2)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    final deepCardId = await insertDeepCard(db, rootId);
    await insertBareCard(db, 'r-trashed', 'r-leaf');
    await db.customStatement(
      'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, '
      "generation, current_box, learned_at) VALUES ('r-trashed', 'eight_box', "
      '1, 1, 2, 0)',
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = 'r-trashed'",
    );
    for (final id in [cardId, deepCardId]) {
      await repo.recordReview(
        cardId: id,
        sessionId: sessionId,
        action: EightBoxAction.remembered,
      );
    }

    final summary = await summaryOf(rootId);

    expect(summary.isSchedulerLocked, isTrue);
    expect(summary.cardCount, 2);
    expect(summary.learnedCardCount, 2);
    expect(summary.openSessionCount, 1);
    expect(summary.hasProgressToLose, isTrue);
  });

  test(
    'an open session alone is progress to lose (UC-SRS-001 step 2)',
    () async {
      final (rootId, _, _) = await insertStudyTree(db, 'r');

      final summary = await summaryOf(rootId);

      expect(summary.learnedCardCount, 0);
      expect(summary.openSessionCount, 1);
      expect(summary.hasProgressToLose, isTrue);
    },
  );

  test('a sub-deck, a missing root and a root in the Trash have no summary '
      '(UC-SRS-001 A4)', () async {
    await insertStudyTree(db, 'r');

    expect(
      await repo.resetSummary(rootDeckId: 'r-leaf'),
      _refusedWith<ResetLearningSummary>(SrsRejection.notARootDeck),
    );
    expect(
      await repo.resetSummary(rootDeckId: 'missing'),
      _refusedWith<ResetLearningSummary>(SrsRejection.notFound),
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE root_id = 'r'",
    );
    expect(
      await repo.resetSummary(rootDeckId: 'r'),
      _refusedWith<ResetLearningSummary>(SrsRejection.notFound),
    );
  });

  test('a tree with no cards has nothing to lose and resets all the same '
      '(UC-SRS-001 A2)', () async {
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      'created_at, updated_at) '
      "VALUES ('empty', 'empty', NULL, 'empty', 1, 'deck', 'eight_box', 1, 1, "
      '0, 0, 0)',
    );

    final summary = await summaryOf('empty');
    final result = await repo.resetLearning(rootDeckId: 'empty');

    expect((summary.cardCount, summary.hasProgressToLose), (0, false));
    expect(result, isA<Ok<void, SrsRejection>>());
    expect((await deckRowOf(db, 'empty')).read<int>('generation'), 2);
  });
}

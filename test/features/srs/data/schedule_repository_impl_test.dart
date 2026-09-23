import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/test_database.dart';

Future<void> _addCard(AppDatabase db, String cardId, String deckId) =>
    db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES (?, ?, 'f', 'b', 0, 0)",
      [cardId, deckId],
    );

/// One tree per [rootId]: a root at generation 1 running [scheduler], a
/// sub-deck `<rootId>-leaf` holding one card, that card's start-value
/// schedule row, and an `in_progress` session of the root.
/// Returns (rootId, cardId, sessionId).
Future<(String, String, String)> _tree(
  AppDatabase db,
  String rootId, {
  String scheduler = 'eight_box',
}) async {
  final cardId = '$rootId-card';
  final sessionId = '$rootId-session';
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, '
    'scheduler_version, generation, sibling_position, created_at, updated_at) '
    "VALUES (?, 'root', NULL, ?, 1, 'deck', ?, 1, 1, 0, 0, 0)",
    [rootId, rootId, scheduler],
  );
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES (?, 'leaf', ?, ?, 2, 'card', 0, 0, 0)",
    ['$rootId-leaf', rootId, rootId],
  );
  await _addCard(db, cardId, '$rootId-leaf');
  await db.customStatement(
    scheduler == 'sm2'
        ? 'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, '
              "ease_factor, interval_days, repetitions) VALUES (?, 'sm2', 1, 1, 2.5, 0, 0)"
        : 'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, '
              "current_box) VALUES (?, 'eight_box', 1, 1, 1)",
    [cardId],
  );
  await db.customStatement(
    'INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, '
    "status, cursor, card_limit, started_at) VALUES (?, ?, ?, 1, 'learning', 'self_assess', "
    "'in_progress', 0, 20, 0)",
    [sessionId, rootId, rootId],
  );
  return (rootId, cardId, sessionId);
}

/// A card two levels below [rootId] (root → branch → deep) in an `eight_box`
/// tree: a statement that reaches only the root's children misses it.
Future<String> _deepCard(AppDatabase db, String rootId) async {
  final cardId = '$rootId-deep-card';
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES (?, 'branch', ?, ?, 2, 'deck', 1, 0, 0), (?, 'deep', ?, ?, 3, 'card', 0, 0, 0)",
    [
      '$rootId-branch',
      rootId,
      rootId,
      '$rootId-deep',
      '$rootId-branch',
      rootId,
    ],
  );
  await _addCard(db, cardId, '$rootId-deep');
  await db.customStatement(
    'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) '
    "VALUES (?, 'eight_box', 1, 1, 1)",
    [cardId],
  );
  return cardId;
}

Future<QueryRow> _row(AppDatabase db, String table, String column, String id) =>
    db
        .customSelect(
          'SELECT * FROM $table WHERE $column = ?',
          variables: [Variable(id)],
        )
        .getSingle();

Future<QueryRow> _deck(AppDatabase db, String id) => _row(db, 'deck', 'id', id);

Future<QueryRow> _schedule(AppDatabase db, String cardId) =>
    _row(db, 'card_schedule', 'card_id', cardId);

Future<QueryRow> _session(AppDatabase db, String id) =>
    _row(db, 'study_session', 'id', id);

/// Rows inserted, updated or deleted on this connection so far: the same
/// number before and after a call proves the call wrote nothing.
Future<int> _writes(AppDatabase db) async =>
    (await db.customSelect('SELECT total_changes() AS n').getSingle())
        .read<int>('n');

void _expectStartValues(
  QueryRow row, {
  required String scheduler,
  required int generation,
}) {
  expect(row.read<String>('scheduler_type'), scheduler);
  expect(row.read<int>('generation'), generation);
  expect(row.data['learned_at'], isNull);
  expect(row.data['due_at'], isNull);
  expect(row.data['last_answered_at'], isNull);
  expect(row.read<int>('answer_count'), 0);
  expect(row.read<int>('lapse_count'), 0);
  if (scheduler == 'sm2') {
    expect(row.data['current_box'], isNull);
    expect(row.read<double>('ease_factor'), 2.5);
    expect(row.read<int>('interval_days'), 0);
    expect(row.read<int>('repetitions'), 0);
    return;
  }
  expect(row.read<int>('current_box'), 1);
  expect(row.data['ease_factor'], isNull);
}

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl repo;
  final now = DateTime(2026, 9, 23);
  setUp(() {
    db = openTestDatabase();
    repo = ScheduleRepositoryImpl(db, now: () => now);
  });
  tearDown(() => db.close());

  test('initializeCard writes the start values of the root scheduler at the root generation (BR-CARD-004)', () async {
    await _tree(db, 'r', scheduler: 'sm2');
    await db.customStatement("UPDATE deck SET generation = 3 WHERE id = 'r'");
    await _addCard(db, 'new', 'r-leaf');

    await repo.initializeCard(cardId: 'new');

    _expectStartValues(
      await _schedule(db, 'new'),
      scheduler: 'sm2',
      generation: 3,
    );
  });

  test('initializeCard of a missing card throws', () async {
    await expectLater(repo.initializeCard(cardId: 'missing'), throwsStateError);
  });

  test(
    'recordReview rejects an action the deck scheduler does not support',
    () async {
      final (_, cardId, sessionId) = await _tree(db, 'r'); // eight_box
      final result = await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: Sm2Action.good,
      );
      expect(
        (result as Rejected<void, SrsRejection>).reason,
        SrsRejection.unsupportedAction,
      );
    },
  );

  test(
    'recordReview writes card_schedule and an append-only review_log row',
    () async {
      final (_, cardId, sessionId) = await _tree(db, 'r');
      final result = await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: EightBoxAction.remembered,
      );
      expect(result, isA<Ok<void, SrsRejection>>());

      expect((await _schedule(db, cardId)).read<int>('current_box'), 2);
      final logCount = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM review_log WHERE card_id = ?',
            variables: [Variable(cardId)],
          )
          .getSingle();
      expect(logCount.read<int>('n'), 1);
    },
  );

  test('reviewing a card deleted mid-session returns notFound and writes no log row', () async {
    final (_, cardId, sessionId) = await _tree(db, 'r');
    await db.customStatement('DELETE FROM card WHERE id = ?', [cardId]);

    final result = await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );
    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.notFound,
    );
    final logCount = await db
        .customSelect('SELECT COUNT(*) AS n FROM review_log')
        .getSingle();
    expect(logCount.read<int>('n'), 0);
  });

  test(
    'a review from a stale-generation session is rejected, not applied',
    () async {
      final (rootId, cardId, sessionId) = await _tree(db, 'r');
      await repo.resetLearning(rootDeckId: rootId); // bumps generation to 2

      final result = await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: EightBoxAction.remembered,
      );
      expect(
        (result as Rejected<void, SrsRejection>).reason,
        SrsRejection.staleGeneration,
      );
    },
  );

  test('resetLearning bumps generation and recreates card_schedule', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    await repo.resetLearning(rootDeckId: rootId);

    expect((await _deck(db, rootId)).read<int>('generation'), 2);
    _expectStartValues(
      await _schedule(db, cardId),
      scheduler: 'eight_box',
      generation: 2,
    );
  });

  test('resetLearning of an sm2 tree writes sm2 start values', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r', scheduler: 'sm2');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: Sm2Action.good,
    );

    await repo.resetLearning(rootDeckId: rootId);

    _expectStartValues(
      await _schedule(db, cardId),
      scheduler: 'sm2',
      generation: 2,
    );
  });

  test('resetLearning unlocks the scheduler and closes the open sessions (BR-SRS-024, BR-STUDY-015)', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    await repo.resetLearning(rootDeckId: rootId);

    expect((await _deck(db, rootId)).data['first_answered_at'], isNull);
    final session = await _session(db, sessionId);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_reset');
    expect(session.data['ended_at'], isNotNull);
  });

  test('resetLearning of a sub-deck is rejected with notARootDeck and writes nothing', () async {
    await _tree(db, 'r');
    final before = await _writes(db);

    final result = await repo.resetLearning(rootDeckId: 'r-leaf');

    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.notARootDeck,
    );
    expect(await _writes(db), before);
  });

  test(
    'changeScheduler before the first review is allowed and keeps generation',
    () async {
      final (rootId, _, _) = await _tree(db, 'r');
      final result = await repo.changeScheduler(
        rootDeckId: rootId,
        newType: SchedulerType.sm2,
      );
      expect(result, isA<Ok<void, SrsRejection>>());

      final root = await _deck(db, rootId);
      expect(root.read<String>('scheduler_type'), 'sm2');
      expect(
        root.read<int>('generation'),
        1,
        reason: 'BR-SRS-002: a change is not a reset',
      );
    },
  );

  test('changeScheduler starts every card of the tree over under the new scheduler (BR-SRS-004)', () async {
    final (rootId, cardId, _) = await _tree(db, 'r');
    final deepCardId = await _deepCard(db, rootId);

    await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);

    _expectStartValues(
      await _schedule(db, cardId),
      scheduler: 'sm2',
      generation: 1,
    );
    _expectStartValues(
      await _schedule(db, deepCardId),
      scheduler: 'sm2',
      generation: 1,
    );
  });

  test(
    'changeScheduler closes the open sessions of the tree (BR-STUDY-016)',
    () async {
      final (rootId, _, sessionId) = await _tree(db, 'r');

      await repo.changeScheduler(
        rootDeckId: rootId,
        newType: SchedulerType.sm2,
      );

      final session = await _session(db, sessionId);
      expect(session.read<String>('status'), 'invalidated');
      expect(session.read<String>('end_reason'), 'scheduler_changed');
      expect(session.data['ended_at'], isNotNull);
    },
  );

  test('changeScheduler leaves other trees alone', () async {
    final (rootId, _, _) = await _tree(db, 'r');
    final (_, otherCardId, otherSessionId) = await _tree(db, 'other');

    await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);

    _expectStartValues(
      await _schedule(db, otherCardId),
      scheduler: 'eight_box',
      generation: 1,
    );
    expect(
      (await _session(db, otherSessionId)).read<String>('status'),
      'in_progress',
    );
  });

  test('changeScheduler to the scheduler the root runs writes nothing (UC-DECK-002 A4)', () async {
    final (rootId, _, _) = await _tree(db, 'r');
    final before = await _writes(db);

    final result = await repo.changeScheduler(
      rootDeckId: rootId,
      newType: SchedulerType.eightBox,
    );

    expect(result, isA<Ok<void, SrsRejection>>());
    expect(await _writes(db), before);
  });

  test('the scheduler the root runs is a no-op on a locked tree too, not a rejection', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );
    final before = await _writes(db);

    final result = await repo.changeScheduler(
      rootDeckId: rootId,
      newType: SchedulerType.eightBox,
    );

    expect(result, isA<Ok<void, SrsRejection>>());
    expect(await _writes(db), before);
  });

  test('changeScheduler after the first review is rejected (locked)', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );
    final before = await _writes(db);

    final result = await repo.changeScheduler(
      rootDeckId: rootId,
      newType: SchedulerType.sm2,
    );
    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.schedulerLocked,
    );
    expect(await _writes(db), before);
  });

  test('changeScheduler of a sub-deck is rejected with notARootDeck and writes nothing', () async {
    await _tree(db, 'r');
    final before = await _writes(db);

    final result = await repo.changeScheduler(
      rootDeckId: 'r-leaf',
      newType: SchedulerType.sm2,
    );

    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.notARootDeck,
    );
    expect(await _writes(db), before);
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
    await _tree(db, 'r');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE root_id = 'r'",
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = 'r-card'",
    );
    final before = await _writes(db);
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
    expect(await _writes(db), before);
  });
}

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';

import '../../../support/srs_fixtures.dart';
import '../../../support/test_database.dart';

// The two writes a study session makes on srs: one turn, and the end of a
// card's learning (UC-STUDY-001 steps 7–11).

Matcher _refusedWith(SrsRejection reason) => isA<Rejected<void, SrsRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

Future<List<QueryRow>> _logs(AppDatabase db) =>
    db.customSelect('SELECT * FROM review_log ORDER BY answered_at').get();

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl repo;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    repo = ScheduleRepositoryImpl(db, now: () => now);
  });
  tearDown(() => db.close());

  ReviewTurn turn(
    String cardId, {
    ReviewKind kind = ReviewKind.learning,
    Object action = EightBoxAction.remembered,
    int generation = 1,
    String? direction,
    DateTime? at,
  }) => ReviewTurn(
    cardId: cardId,
    sessionId: 'r-session',
    generation: generation,
    kind: kind,
    modeCode: 'recall',
    action: action,
    directionCode: direction,
    answeredAt: at ?? now,
  );

  test('a learning turn is logged and changes nothing but last_answered_at '
      '(BR-STUDY-053, BR-SRS-018)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');

    expect(await repo.recordTurn(turn(cardId)), isA<Ok<void, SrsRejection>>());

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.data['learned_at'], isNull);
    expect(schedule.data['due_at'], isNull);
    expect(schedule.read<DateTime>('last_answered_at'), now);
    expect(schedule.read<int>('current_box'), 1);
    expect(schedule.read<int>('answer_count'), 0);
    final [log] = await _logs(db);
    expect(log.read<String>('kind'), 'learning');
    expect(log.read<String>('mode'), 'recall');
    expect(log.read<String>('action'), 'remembered');
    expect(log.read<String>('session_id'), 'r-session');
    expect(log.read<String>('scheduler_type'), 'eight_box');
    expect(log.read<int>('generation'), 1);
    expect((log.read<int>('previous_box'), log.read<int>('next_box')), (1, 1));
    expect(log.data['next_due_at'], isNull);
  });

  test('a relearning turn keeps the whole schedule (BR-SRS-017, '
      'invariant 14)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final later = now.add(const Duration(minutes: 5));

    await repo.recordTurn(
      turn(
        cardId,
        kind: ReviewKind.relearning,
        action: EightBoxAction.forgotten,
        at: later,
      ),
    );

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.read<DateTime>('due_at'), dueAtLocalMidnight(now, 1));
    expect(schedule.read<int>('current_box'), 1);
    expect(schedule.read<DateTime>('last_answered_at'), later);
    expect(
      (schedule.read<int>('answer_count'), schedule.read<int>('lapse_count')),
      (0, 0),
    );
    final [log] = await _logs(db);
    expect(log.read<String>('kind'), 'relearning');
    expect((log.read<int>('previous_box'), log.read<int>('next_box')), (1, 1));
    expect(log.read<DateTime>('next_due_at'), dueAtLocalMidnight(now, 1));
  });

  test('a scheduled turn runs the scheduler and logs the values before and '
      'after (BR-SRS-016, BR-SRS-019)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final nextDay = DateTime(2026, 9, 25, 7);

    await repo.recordTurn(
      turn(cardId, kind: ReviewKind.scheduled, at: nextDay),
    );

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.read<int>('current_box'), 2);
    expect(schedule.read<DateTime>('due_at'), DateTime(2026, 9, 27));
    expect(schedule.read<int>('answer_count'), 1);
    final [log] = await _logs(db);
    expect(log.read<String>('kind'), 'scheduled');
    expect((log.read<int>('previous_box'), log.read<int>('next_box')), (1, 2));
    expect(log.read<DateTime>('next_due_at'), DateTime(2026, 9, 27));
  });

  test('a turn keeps what its mode adds: the reason of a recall timeout, the '
      'comparison version and the hint of a fill (BR-STUDY-027, BR-STUDY-028, '
      'BR-STUDY-034)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');

    await repo.recordTurn(
      ReviewTurn(
        cardId: cardId,
        sessionId: 'r-session',
        generation: 1,
        kind: ReviewKind.learning,
        modeCode: 'recall',
        action: EightBoxAction.forgotten,
        answeredAt: now,
        outcomeReasonCode: 'timeout',
      ),
    );
    await repo.recordTurn(
      ReviewTurn(
        cardId: cardId,
        sessionId: 'r-session',
        generation: 1,
        kind: ReviewKind.relearning,
        modeCode: 'fill',
        action: EightBoxAction.remembered,
        answeredAt: now.add(const Duration(minutes: 1)),
        comparisonVersion: 1,
        usedHint: true,
      ),
    );

    final [timeout, fill] = await _logs(db);
    expect(timeout.read<String>('outcome_reason'), 'timeout');
    expect(timeout.data['comparison_version'], isNull);
    expect(timeout.data['used_hint'], isNull);
    expect(fill.data['outcome_reason'], isNull);
    expect(fill.read<int>('comparison_version'), 1);
    expect(fill.read<bool>('used_hint'), isTrue);
  });

  test("a mode's column on another mode is a bug the schema refuses, and the "
      'turn writes nothing (invariants 22, 23)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');

    await expectLater(
      repo.recordTurn(
        ReviewTurn(
          cardId: cardId,
          sessionId: 'r-session',
          generation: 1,
          kind: ReviewKind.learning,
          modeCode: 'recall',
          action: EightBoxAction.remembered,
          answeredAt: now,
          comparisonVersion: 1,
        ),
      ),
      throwsA(isA<ConstraintFailure>()),
    );
    expect(await _logs(db), isEmpty);
  });

  test('a turn keeps the direction it is given (BR-MODE-016)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r', scheduler: 'sm2');

    await repo.recordTurn(
      turn(cardId, action: Sm2Action.good, direction: 'meaning_to_korean'),
    );

    final [log] = await _logs(db);
    expect(log.read<String>('direction'), 'meaning_to_korean');
  });

  test('a scheduled turn on a card still learning is a bug that writes '
      'nothing (BR-STUDY-058, invariant 25)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    await expectLater(
      repo.recordTurn(turn(cardId, kind: ReviewKind.scheduled)),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
    expect(await totalChanges(db), before);
  });

  test('an action the root scheduler does not support is refused and '
      'writes nothing (BR-STUDY-009)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    expect(
      await repo.recordTurn(turn(cardId, action: Sm2Action.good)),
      _refusedWith(SrsRejection.unsupportedAction),
    );
    expect(await totalChanges(db), before);
  });

  test('a turn of an older generation is refused and writes nothing '
      '(BR-SRS-026)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await repo.resetLearning(rootDeckId: rootId);
    final before = await totalChanges(db);

    expect(
      await repo.recordTurn(turn(cardId)),
      _refusedWith(SrsRejection.staleGeneration),
    );
    expect(
      await repo.completeLearning(cardId: cardId, generation: 1),
      _refusedWith(SrsRejection.staleGeneration),
    );
    expect(await totalChanges(db), before);
  });

  test(
    'a card deleted mid-session is notFound and nothing is written',
    () async {
      final (_, cardId, _) = await insertStudyTree(db, 'r');
      await db.customStatement('DELETE FROM card WHERE id = ?', [cardId]);
      final before = await totalChanges(db);

      expect(
        await repo.recordTurn(turn(cardId)),
        _refusedWith(SrsRejection.notFound),
      );
      expect(
        await repo.completeLearning(cardId: cardId, generation: 1),
        _refusedWith(SrsRejection.notFound),
      );
      expect(await totalChanges(db), before);
    },
  );

  test('a card in the Trash is notFound: the study flow never writes it '
      '(BE-C3)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
      [cardId],
    );
    final before = await totalChanges(db);

    expect(
      await repo.recordTurn(turn(cardId)),
      _refusedWith(SrsRejection.notFound),
    );
    expect(
      await repo.completeLearning(cardId: cardId, generation: 1),
      _refusedWith(SrsRejection.notFound),
    );
    expect(await totalChanges(db), before);
  });

  test('a card whose deck is in the Trash is notFound (BE-C3)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = 'r-leaf'",
    );

    expect(
      await repo.recordTurn(turn(cardId)),
      _refusedWith(SrsRejection.notFound),
    );
  });

  test('completing learning starts the schedule at box 1, due at the next '
      'local midnight, with no review_log row (BR-STUDY-053)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');

    expect(
      await repo.completeLearning(cardId: cardId, generation: 1),
      isA<Ok<void, SrsRejection>>(),
    );

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.read<DateTime>('learned_at'), now);
    expect(schedule.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    expect(schedule.read<int>('current_box'), 1);
    expect(schedule.read<int>('answer_count'), 0);
    expect(await _logs(db), isEmpty);
  });

  test('completing learning of an sm2 card starts interval 1 with one '
      'repetition (spec D6)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r', scheduler: 'sm2');

    await repo.completeLearning(cardId: cardId, generation: 1);

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.read<int>('interval_days'), 1);
    expect(schedule.read<int>('repetitions'), 1);
    expect(schedule.read<double>('ease_factor'), 2.5);
    expect(schedule.read<DateTime>('due_at'), DateTime(2026, 9, 25));
  });

  test('the first completion locks the scheduler and a later one keeps its '
      'mark (BR-SRS-003)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    final deepCardId = await insertDeepCard(db, rootId);
    final later = now.add(const Duration(hours: 1));

    await repo.completeLearning(cardId: cardId, generation: 1);
    await repo.completeLearning(cardId: deepCardId, generation: 1, now: later);

    final root = await deckRowOf(db, rootId);
    expect(root.read<DateTime>('first_answered_at'), now);
    expect(
      (await scheduleRowOf(db, deepCardId)).read<DateTime>('learned_at'),
      later,
    );
  });

  test('completing learning of a learned card is a bug that writes '
      'nothing', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final before = await totalChanges(db);

    await expectLater(
      repo.completeLearning(cardId: cardId, generation: 1),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
    expect(await totalChanges(db), before);
  });

  test('a turn reaches the card through its own row only', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    final (_, otherCardId, _) = await insertStudyTree(db, 'other');

    await repo.recordTurn(turn(cardId));

    final other = await scheduleRowOf(db, otherCardId);
    expect(other.data['last_answered_at'], isNull);
    final count = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM review_log WHERE card_id = ?',
          variables: [Variable(otherCardId)],
        )
        .getSingle();
    expect(count.read<int>('n'), 0);
  });
}

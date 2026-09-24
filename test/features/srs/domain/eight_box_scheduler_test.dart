import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';

CardScheduleState _newCard({int generation = 1}) => CardScheduleState.eightBox(
  generation: generation,
  learnedAt: null,
  dueAt: null,
  lastAnsweredAt: null,
  answerCount: 0,
  lapseCount: 0,
  currentBox: 1,
);

void main() {
  final now = DateTime(2026, 9, 23, 8);

  test('supportedActions is exactly forgotten and remembered', () {
    expect(eightBoxScheduler.supportedActions, {
      EightBoxAction.forgotten,
      EightBoxAction.remembered,
    });
  });

  test('remembered on a new card sets learnedAt and moves to box 2', () {
    final (next, log) = eightBoxScheduler.next(
      _newCard(),
      EightBoxAction.remembered,
      now,
    );
    expect(next.currentBox, 2);
    expect(next.learnedAt, now);
    expect(log.kind, ReviewKind.learning);
    expect(log.previousBox, 1);
    expect(log.nextBox, 2);
  });

  test(
    'forgotten on a new card stays in learning, box unchanged, no due date',
    () {
      final (next, log) = eightBoxScheduler.next(
        _newCard(),
        EightBoxAction.forgotten,
        now,
      );
      expect(next.currentBox, 1);
      expect(next.dueAt, isNull);
      expect(log.kind, ReviewKind.learning);
    },
  );

  test('box 8 remembered schedules 128 days out (BR-SRS box ladder)', () {
    final learned = _newCard().copyWith(learnedAt: now, currentBox: 8);
    final (next, log) = eightBoxScheduler.next(
      learned,
      EightBoxAction.remembered,
      now,
    );
    expect(next.dueAt, dueAtLocalMidnight(now, 128));
    expect(log.kind, ReviewKind.scheduled);
    expect(log.nextDueAt, next.dueAt);
  });

  test('forgotten after learning is relearning and does not change dueAt', () {
    final scheduled = _newCard().copyWith(
      learnedAt: now,
      currentBox: 4,
      dueAt: dueAtLocalMidnight(now, 8),
    );
    final (next, log) = eightBoxScheduler.next(
      scheduled,
      EightBoxAction.forgotten,
      now,
    );
    expect(log.kind, ReviewKind.relearning);
    expect(
      next.dueAt,
      scheduled.dueAt,
      reason: 'BR-SRS-017: relearning does not change the schedule',
    );
    expect(log.previousBox, log.nextBox);
  });

  // BR-SRS-018: last_answered_at on every turn, answer_count on scheduled
  // turns only. A lapse is counted on the forgotten turn of a learned card,
  // as Task 4 counts sm2's `again` (Clarification 15 records the kind model).
  test(
    'every answer stamps lastAnsweredAt; only a scheduled answer counts',
    () {
      final (learning, _) = eightBoxScheduler.next(
        _newCard(),
        EightBoxAction.forgotten,
        now,
      );
      expect(learning.lastAnsweredAt, now);
      expect(learning.answerCount, 0);

      final learned = _newCard().copyWith(
        learnedAt: now,
        currentBox: 3,
        dueAt: dueAtLocalMidnight(now, 4),
      );
      final (scheduled, _) = eightBoxScheduler.next(
        learned,
        EightBoxAction.remembered,
        now,
      );
      expect(scheduled.answerCount, 1);
      expect(scheduled.lapseCount, 0);

      final (relearning, _) = eightBoxScheduler.next(
        learned,
        EightBoxAction.forgotten,
        now,
      );
      expect(relearning.lastAnsweredAt, now);
      expect(relearning.answerCount, 0);
      expect(relearning.lapseCount, 1);
    },
  );

  test('an action of another scheduler is refused', () {
    expect(
      () => eightBoxScheduler.next(_newCard(), 'good', now),
      throwsArgumentError,
    );
  });
}

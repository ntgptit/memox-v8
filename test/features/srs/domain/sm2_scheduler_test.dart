import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';

CardScheduleState _newCard() => const CardScheduleState.sm2(
  generation: 1,
  learnedAt: null,
  dueAt: null,
  lastAnsweredAt: null,
  answerCount: 0,
  lapseCount: 0,
  easeFactor: 2.5,
  intervalDays: 0,
  repetitions: 0,
);

void main() {
  final now = DateTime(2026, 9, 23, 8);

  test('supportedActions is again/hard/good/easy', () {
    expect(sm2Scheduler.supportedActions, {
      Sm2Action.again,
      Sm2Action.hard,
      Sm2Action.good,
      Sm2Action.easy,
    });
  });

  test('again always resets repetitions and floors ease at 1.3', () {
    final low = _newCard().copyWith(easeFactor: 1.3, repetitions: 5);
    final (next, log) = sm2Scheduler.next(low, Sm2Action.again, now);
    expect(next.repetitions, 0);
    expect(next.easeFactor, greaterThanOrEqualTo(1.3));
    expect(log.previousEaseFactor, 1.3);
  });

  test('good on a new card sets learnedAt and interval 1', () {
    final (next, log) = sm2Scheduler.next(_newCard(), Sm2Action.good, now);
    expect(next.learnedAt, now);
    expect(next.intervalDays, 1);
    expect(log.kind, ReviewKind.learning);
  });

  test('easy grows the interval faster than good from the same state', () {
    final learned = _newCard().copyWith(
      learnedAt: now,
      repetitions: 2,
      intervalDays: 6,
    );
    final (goodNext, _) = sm2Scheduler.next(learned, Sm2Action.good, now);
    final (easyNext, _) = sm2Scheduler.next(learned, Sm2Action.easy, now);
    expect(easyNext.intervalDays, greaterThan(goodNext.intervalDays!));
  });

  test('again after learnedAt is relearning and does not change dueAt', () {
    final scheduled = _newCard().copyWith(
      learnedAt: now,
      repetitions: 3,
      intervalDays: 10,
      dueAt: dueAtLocalMidnight(now, 10),
    );
    final (next, log) = sm2Scheduler.next(scheduled, Sm2Action.again, now);
    expect(log.kind, ReviewKind.relearning);
    expect(next.dueAt, scheduled.dueAt);
    expect(log.previousIntervalDays, log.nextIntervalDays);
  });

  test('a scheduled good follows the SM-2 ladder: 1 day, then 6, then interval x ease', () {
    final learned = _newCard().copyWith(
      learnedAt: now,
      repetitions: 1,
      intervalDays: 1,
    );
    final (second, secondLog) = sm2Scheduler.next(learned, Sm2Action.good, now);
    expect(secondLog.kind, ReviewKind.scheduled);
    expect(second.intervalDays, 6);
    expect(second.dueAt, dueAtLocalMidnight(now, 6));
    expect(secondLog.nextDueAt, second.dueAt);

    final (third, _) = sm2Scheduler.next(second, Sm2Action.good, now);
    // good keeps ease 2.5: 6 x 2.5 = 15.
    expect(third.intervalDays, 15);
  });

  // BR-SRS-018 counters, with the lapse on the again of a learned card
  // (Clarification 15 records the kind model).
  test(
    'every answer stamps lastAnsweredAt; only a scheduled answer counts',
    () {
      final (learning, _) = sm2Scheduler.next(_newCard(), Sm2Action.hard, now);
      expect(learning.lastAnsweredAt, now);
      expect(learning.answerCount, 0);

      final learned = _newCard().copyWith(
        learnedAt: now,
        repetitions: 2,
        intervalDays: 6,
      );
      final (scheduled, _) = sm2Scheduler.next(learned, Sm2Action.good, now);
      expect(scheduled.answerCount, 1);
      expect(scheduled.lapseCount, 0);

      final (relearning, _) = sm2Scheduler.next(learned, Sm2Action.again, now);
      expect(relearning.answerCount, 0);
      expect(relearning.lapseCount, 1);
      expect(
        relearning.easeFactor,
        learned.easeFactor,
        reason: 'BR-SRS-017: relearning keeps the ease',
      );
    },
  );

  test('an action of another scheduler is refused', () {
    expect(
      () => sm2Scheduler.next(_newCard(), 'remembered', now),
      throwsArgumentError,
    );
  });
}

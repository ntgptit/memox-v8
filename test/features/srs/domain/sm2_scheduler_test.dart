import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';

final _now = DateTime(2026, 9, 23, 8);

CardScheduleState _newCard() =>
    CardScheduleState.initial(SchedulerType.sm2, generation: 1);

CardScheduleState _learned({
  double ease = 2.5,
  int interval = 1,
  int repetitions = 1,
}) => _newCard().copyWith(
  learnedAt: _now,
  dueAt: dueAtLocalMidnight(_now, interval),
  easeFactor: ease,
  intervalDays: interval,
  repetitions: repetitions,
);

void main() {
  test('supportedActions is again/hard/good/easy', () {
    expect(sm2Scheduler.supportedActions, {
      Sm2Action.again,
      Sm2Action.hard,
      Sm2Action.good,
      Sm2Action.easy,
    });
  });

  test('again is the one lapse (BR-SRS-018)', () {
    expect(sm2Scheduler.isLapse(Sm2Action.again), isTrue);
    for (final action in [Sm2Action.hard, Sm2Action.good, Sm2Action.easy]) {
      expect(sm2Scheduler.isLapse(action), isFalse);
    }
  });

  test('a card that finishes learning starts at interval 1 with one '
      'repetition, due at the next local midnight, ease untouched '
      '(BR-STUDY-053; spec D6)', () {
    final learned = sm2Scheduler.learned(_newCard(), _now);

    expect(learned.learnedAt, _now);
    expect((learned.intervalDays, learned.repetitions), (1, 1));
    expect(learned.easeFactor, 2.5);
    expect(learned.dueAt, DateTime(2026, 9, 24));
    expect((learned.answerCount, learned.lapseCount), (0, 0));
  });

  test('learning a card that is already learned is a programming error', () {
    expect(() => sm2Scheduler.learned(_learned(), _now), throwsArgumentError);
  });

  for (final (action, ease) in [
    (Sm2Action.again, 1.7),
    (Sm2Action.hard, 2.36),
    (Sm2Action.good, 2.5),
    (Sm2Action.easy, 2.6),
  ]) {
    test('${action.name} takes the ease from 2.5 to $ease: q is 0, 3, 4, 5 '
        '(BR-SRS-010, BR-SRS-012)', () {
      final (state, log) = sm2Scheduler.next(_learned(), action, _now);

      expect(state.easeFactor, closeTo(ease, 1e-9));
      expect(log.previousEaseFactor, 2.5);
      expect(log.nextEaseFactor, state.easeFactor);
    });
  }

  test('the ease never falls under 1.3 (BR-SRS-012)', () {
    final (state, _) = sm2Scheduler.next(
      _learned(ease: 1.4),
      Sm2Action.again,
      _now,
    );

    expect(state.easeFactor, 1.3);
  });

  test('again starts the repetitions over at interval 1, due the next day '
      '(BR-SRS-011)', () {
    final (state, log) = sm2Scheduler.next(
      _learned(interval: 15, repetitions: 3),
      Sm2Action.again,
      _now,
    );

    expect((state.intervalDays, state.repetitions), (1, 0));
    expect(state.dueAt, dueAtLocalMidnight(_now, 1));
    expect(log.kind, ReviewKind.scheduled);
    expect((log.previousIntervalDays, log.nextIntervalDays), (15, 1));
  });

  test('good climbs the ladder from the learned start: 6 days, then the '
      'interval times the ease (BR-SRS-011)', () {
    final (second, log) = sm2Scheduler.next(_learned(), Sm2Action.good, _now);
    final (third, _) = sm2Scheduler.next(second, Sm2Action.good, _now);

    expect((second.intervalDays, second.repetitions), (6, 2));
    expect(second.dueAt, dueAtLocalMidnight(_now, 6));
    expect(log.nextDueAt, second.dueAt);
    expect((third.intervalDays, third.repetitions), (15, 3));
  });

  test('the interval is multiplied by the ease this turn produced: hard at '
      'interval 10 gives 24 days, not 25 (BR-SRS-011)', () {
    final (state, _) = sm2Scheduler.next(
      _learned(interval: 10, repetitions: 3),
      Sm2Action.hard,
      _now,
    );

    expect(state.intervalDays, 24);
    expect(state.dueAt, dueAtLocalMidnight(_now, 24));
  });

  test('a scheduled turn stamps lastAnsweredAt, counts the answer, and '
      'counts a lapse on again only (BR-SRS-018)', () {
    final answeredAt = _now.add(const Duration(days: 6));
    final (good, _) = sm2Scheduler.next(_learned(), Sm2Action.good, answeredAt);
    final (again, _) = sm2Scheduler.next(
      _learned(),
      Sm2Action.again,
      answeredAt,
    );

    expect(good.lastAnsweredAt, answeredAt);
    expect((good.answerCount, good.lapseCount), (1, 0));
    expect((again.answerCount, again.lapseCount), (1, 1));
  });

  test('a scheduled turn on a card still learning is a programming error '
      '(BR-STUDY-058)', () {
    expect(
      () => sm2Scheduler.next(_newCard(), Sm2Action.good, _now),
      throwsArgumentError,
    );
  });

  test('an action of another scheduler is refused', () {
    expect(
      () => sm2Scheduler.next(_learned(), 'remembered', _now),
      throwsArgumentError,
    );
  });
}

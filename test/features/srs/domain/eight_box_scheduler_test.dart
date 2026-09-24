import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

final _now = DateTime(2026, 9, 23, 8);

CardScheduleState _newCard() =>
    CardScheduleState.initial(SchedulerType.eightBox, generation: 1);

CardScheduleState _learnedIn(int box) => _newCard().copyWith(
  learnedAt: _now,
  currentBox: box,
  dueAt: dueAtLocalMidnight(_now, 1),
);

void main() {
  test('supportedActions is exactly forgotten and remembered', () {
    expect(eightBoxScheduler.supportedActions, {
      EightBoxAction.forgotten,
      EightBoxAction.remembered,
    });
  });

  test('forgotten is the one lapse (BR-SRS-018)', () {
    expect(eightBoxScheduler.isLapse(EightBoxAction.forgotten), isTrue);
    expect(eightBoxScheduler.isLapse(EightBoxAction.remembered), isFalse);
  });

  test('a card that finishes learning starts in box 1, due at the next '
      'local midnight (BR-STUDY-053, BR-STUDY-074)', () {
    final learned = eightBoxScheduler.learned(_newCard(), _now);

    expect(learned.learnedAt, _now);
    expect(learned.currentBox, 1);
    expect(learned.dueAt, DateTime(2026, 9, 24));
    expect(learned.lastAnsweredAt, isNull);
    expect((learned.answerCount, learned.lapseCount), (0, 0));
  });

  test('learning a card that is already learned is a programming error', () {
    expect(
      () => eightBoxScheduler.learned(_learnedIn(3), _now),
      throwsArgumentError,
    );
  });

  for (final (box, target, days) in [
    (1, 2, 2),
    (2, 3, 4),
    (3, 4, 8),
    (4, 5, 16),
    (5, 6, 32),
    (6, 7, 64),
    (7, 8, 128),
    (8, 8, 128),
  ]) {
    test('remembered in box $box moves to box $target, due in $days days '
        '(BR-SRS-008, BR-SRS-009)', () {
      final (state, log) = eightBoxScheduler.next(
        _learnedIn(box),
        EightBoxAction.remembered,
        _now,
      );

      expect(state.currentBox, target);
      expect(state.dueAt, dueAtLocalMidnight(_now, days));
      expect(log.kind, ReviewKind.scheduled);
      expect((log.previousBox, log.nextBox), (box, target));
      expect(log.nextDueAt, state.dueAt);
    });
  }

  test('forgotten sends a learned card back to box 1, due the next day '
      '(BR-SRS-008)', () {
    final (state, log) = eightBoxScheduler.next(
      _learnedIn(5),
      EightBoxAction.forgotten,
      _now,
    );

    expect(state.currentBox, 1);
    expect(state.dueAt, dueAtLocalMidnight(_now, 1));
    expect((log.previousBox, log.nextBox), (5, 1));
  });

  test('a scheduled turn stamps lastAnsweredAt, counts the answer, and '
      'counts a lapse on forgotten only (BR-SRS-018)', () {
    final answeredAt = _now.add(const Duration(days: 3));
    final (remembered, _) = eightBoxScheduler.next(
      _learnedIn(3),
      EightBoxAction.remembered,
      answeredAt,
    );
    final (forgotten, _) = eightBoxScheduler.next(
      _learnedIn(3),
      EightBoxAction.forgotten,
      answeredAt,
    );

    expect(remembered.lastAnsweredAt, answeredAt);
    expect((remembered.answerCount, remembered.lapseCount), (1, 0));
    expect((forgotten.answerCount, forgotten.lapseCount), (1, 1));
  });

  test('a scheduled turn on a card still learning is a programming error '
      '(BR-STUDY-058)', () {
    expect(
      () => eightBoxScheduler.next(_newCard(), EightBoxAction.remembered, _now),
      throwsArgumentError,
    );
  });

  test('an action of another scheduler is refused', () {
    expect(
      () => eightBoxScheduler.next(_learnedIn(1), 'good', _now),
      throwsArgumentError,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

void main() {
  test('an eight_box card starts in box 1, unlearned and unscheduled (BR-CARD-004)', () {
    final state = CardScheduleState.initial(
      SchedulerType.eightBox,
      generation: 3,
    );
    expect(state.generation, 3);
    expect(state.learnedAt, isNull);
    expect(state.dueAt, isNull);
    expect(state.lastAnsweredAt, isNull);
    expect(state.answerCount, 0);
    expect(state.lapseCount, 0);
    expect(state.currentBox, 1);
    expect(state.easeFactor, isNull);
    expect(state.intervalDays, isNull);
    expect(state.repetitions, isNull);
  });

  test(
    'an sm2 card starts at ease 2.5, interval 0, repetition 0 (BR-CARD-004)',
    () {
      final state = CardScheduleState.initial(SchedulerType.sm2, generation: 1);
      expect(state.generation, 1);
      expect(state.learnedAt, isNull);
      expect(state.dueAt, isNull);
      expect(state.lastAnsweredAt, isNull);
      expect(state.answerCount, 0);
      expect(state.lapseCount, 0);
      expect(state.currentBox, isNull);
      expect(state.easeFactor, 2.5);
      expect(state.intervalDays, 0);
      expect(state.repetitions, 0);
    },
  );

  test('fromColumns reads the columns of the scheduler the row runs', () {
    final learned = DateTime(2026, 9, 20);
    final eightBox = CardScheduleState.fromColumns(
      type: SchedulerType.eightBox,
      generation: 2,
      learnedAt: learned,
      dueAt: DateTime(2026, 9, 23),
      lastAnsweredAt: learned,
      answerCount: 3,
      lapseCount: 1,
      currentBox: 4,
      easeFactor: null,
      intervalDays: null,
      repetitions: null,
    );
    final sm2 = CardScheduleState.fromColumns(
      type: SchedulerType.sm2,
      generation: 1,
      learnedAt: null,
      dueAt: null,
      lastAnsweredAt: null,
      answerCount: 0,
      lapseCount: 0,
      currentBox: null,
      easeFactor: 2.36,
      intervalDays: 6,
      repetitions: 2,
    );

    expect(
      (eightBox.generation, eightBox.currentBox, eightBox.answerCount),
      (2, 4, 3),
    );
    expect(eightBox.easeFactor, isNull);
    expect((sm2.easeFactor, sm2.intervalDays, sm2.repetitions), (2.36, 6, 2));
    expect(sm2.currentBox, isNull);
  });
}

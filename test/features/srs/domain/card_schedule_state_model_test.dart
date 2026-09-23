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
}

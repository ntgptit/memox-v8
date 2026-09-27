import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/interval_preview_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';

// FE-A6 D11b: the preview is the write's own formula (handoff 16a).

void main() {
  final now = DateTime(2026, 9, 24, 9);
  final state = CardScheduleState.sm2(
    generation: 1,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
    lastAnsweredAt: DateTime(2026, 9, 14),
    answerCount: 3,
    lapseCount: 0,
    easeFactor: 2.5,
    intervalDays: 10,
    repetitions: 2,
  );

  test('each action gives what next would give, in supportedActions order', () {
    final preview = nextIntervalsOf(sm2Scheduler, state, now);

    expect(preview.keys, sm2Scheduler.supportedActions);
    for (final action in sm2Scheduler.supportedActions) {
      expect(
        preview[action],
        sm2Scheduler.next(state, action, now).$2.nextIntervalDays,
      );
    }
    expect(preview, {
      Sm2Action.again: 1,
      Sm2Action.hard: 24,
      Sm2Action.good: 25,
      Sm2Action.easy: 26,
    });
  });
}

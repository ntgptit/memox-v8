import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';

/// BR-SRS-009: the interval of each box, in days.
const _intervalDaysByBox = {
  1: 1,
  2: 2,
  3: 4,
  4: 8,
  5: 16,
  6: 32,
  7: 64,
  8: 128,
};
const _lastBox = 8;

typedef _Step = (CardScheduleState, ReviewLogEntry);

/// The `eight_box` scheduler (BR-SRS-008, BR-SRS-009). Which answers change
/// the schedule, and how they are counted, follows this plan's kind model;
/// Clarification 15 of the foundation plan records where it differs from the
/// study rules.
final class EightBoxScheduler implements SrsScheduler {
  const EightBoxScheduler();

  @override
  SchedulerType get type => SchedulerType.eightBox;

  @override
  int get version => 1;

  @override
  Set<Object> get supportedActions => const {
    EightBoxAction.forgotten,
    EightBoxAction.remembered,
  };

  @override
  (CardScheduleState, ReviewLogEntry) next(
    CardScheduleState state,
    Object action,
    DateTime now,
  ) {
    if (action is! EightBoxAction) {
      throw ArgumentError.value(action, 'action', 'not an eight_box action');
    }
    final box = state.currentBox;
    if (box == null) {
      throw ArgumentError.value(state, 'state', 'not an eight_box state');
    }
    final answered = state.copyWith(lastAnsweredAt: now);
    if (state.learnedAt == null) return _learning(answered, action, box, now);
    return switch (action) {
      EightBoxAction.remembered => _scheduled(answered, box, now),
      EightBoxAction.forgotten => _relearning(answered, box),
    };
  }

  /// Before the card is learned: `remembered` learns it and moves it up one
  /// box, `forgotten` leaves it where it is. No due date either way.
  _Step _learning(
    CardScheduleState state,
    EightBoxAction action,
    int box,
    DateTime now,
  ) {
    if (action == EightBoxAction.forgotten) {
      return (
        state,
        ReviewLogEntry(
          kind: ReviewKind.learning,
          previousBox: box,
          nextBox: box,
        ),
      );
    }
    final nextBox = _promoted(box);
    return (
      state.copyWith(learnedAt: now, currentBox: nextBox),
      ReviewLogEntry(
        kind: ReviewKind.learning,
        previousBox: box,
        nextBox: nextBox,
      ),
    );
  }

  /// A learned card remembered: one box up (box 8 stays 8) and due at local
  /// midnight of the box's interval (BR-SRS-009, BR-STUDY-074).
  _Step _scheduled(CardScheduleState state, int box, DateTime now) {
    final nextBox = _promoted(box);
    final dueAt = dueAtLocalMidnight(now, _intervalDaysByBox[nextBox]!);
    return (
      state.copyWith(
        currentBox: nextBox,
        dueAt: dueAt,
        answerCount: state.answerCount + 1,
      ),
      ReviewLogEntry(
        kind: ReviewKind.scheduled,
        previousBox: box,
        nextBox: nextBox,
        nextDueAt: dueAt,
      ),
    );
  }

  /// A learned card forgotten: box and due date unchanged (BR-SRS-017),
  /// one more lapse.
  _Step _relearning(CardScheduleState state, int box) => (
    state.copyWith(lapseCount: state.lapseCount + 1),
    ReviewLogEntry(
      kind: ReviewKind.relearning,
      previousBox: box,
      nextBox: box,
      nextDueAt: state.dueAt,
    ),
  );

  int _promoted(int box) => box == _lastBox ? _lastBox : box + 1;
}

const EightBoxScheduler eightBoxScheduler = EightBoxScheduler();

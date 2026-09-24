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
const _firstBox = 1;
const _lastBox = 8;

/// The `eight_box` scheduler (BR-SRS-008, BR-SRS-009).
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
  bool isLapse(Object action) => action == EightBoxAction.forgotten;

  /// `forgotten` goes back to box 1 and `remembered` one box up, box 8
  /// staying 8; the card is due at local midnight of the target box's
  /// interval (BR-SRS-008, BR-SRS-009, BR-STUDY-074).
  @override
  (CardScheduleState, ReviewLogEntry) next(
    CardScheduleState state,
    Object action,
    DateTime now,
  ) {
    if (action is! EightBoxAction) {
      throw ArgumentError.value(action, 'action', 'not an eight_box action');
    }
    final box = _boxOf(state);
    if (state.learnedAt == null) {
      throw ArgumentError.value(state, 'state', 'a card still learning');
    }
    final target = switch (action) {
      EightBoxAction.forgotten => _firstBox,
      EightBoxAction.remembered => box == _lastBox ? _lastBox : box + 1,
    };
    final dueAt = dueAtLocalMidnight(now, _intervalDaysByBox[target]!);
    final lapses = isLapse(action) ? 1 : 0;
    return (
      state.copyWith(
        currentBox: target,
        dueAt: dueAt,
        lastAnsweredAt: now,
        answerCount: state.answerCount + 1,
        lapseCount: state.lapseCount + lapses,
      ),
      ReviewLogEntry(
        kind: ReviewKind.scheduled,
        previousBox: box,
        nextBox: target,
        nextDueAt: dueAt,
      ),
    );
  }

  /// Box 1, due the next local day (BR-STUDY-053).
  @override
  CardScheduleState learned(CardScheduleState state, DateTime now) {
    _boxOf(state);
    if (state.learnedAt != null) {
      throw ArgumentError.value(state, 'state', 'a card already learned');
    }
    return state.copyWith(
      learnedAt: now,
      currentBox: _firstBox,
      dueAt: dueAtLocalMidnight(now, _intervalDaysByBox[_firstBox]!),
    );
  }

  int _boxOf(CardScheduleState state) {
    final box = state.currentBox;
    if (box == null) {
      throw ArgumentError.value(state, 'state', 'not an eight_box state');
    }
    return box;
  }
}

const EightBoxScheduler eightBoxScheduler = EightBoxScheduler();

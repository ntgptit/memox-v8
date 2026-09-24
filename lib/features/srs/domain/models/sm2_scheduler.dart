import 'dart:math' as math;

import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';

/// SM-2's quality `q` of each action (BR-SRS-010).
const _qualityOf = {
  Sm2Action.again: 0,
  Sm2Action.hard: 3,
  Sm2Action.good: 4,
  Sm2Action.easy: 5,
};
const _perfectQuality = 5;
const _passingQuality = 3;
const _minEase = 1.3;
const _firstIntervalDays = 1;
const _secondIntervalDays = 6;

/// The `sm2` scheduler: classic SM-2 with a 1.3 ease floor (BR-SRS-010,
/// BR-SRS-011, BR-SRS-012).
final class Sm2Scheduler implements SrsScheduler {
  const Sm2Scheduler();

  @override
  SchedulerType get type => SchedulerType.sm2;

  @override
  int get version => 1;

  @override
  Set<Object> get supportedActions => const {
    Sm2Action.again,
    Sm2Action.hard,
    Sm2Action.good,
    Sm2Action.easy,
  };

  @override
  bool isLapse(Object action) => action == Sm2Action.again;

  /// The ease first, from this turn's `q`; then `q < 3` starts the
  /// repetitions over at 1 day, and a pass goes 1 day, 6 days, then the
  /// interval times the new ease (BR-SRS-011). Due at local midnight
  /// (BR-STUDY-074).
  @override
  (CardScheduleState, ReviewLogEntry) next(
    CardScheduleState state,
    Object action,
    DateTime now,
  ) {
    if (action is! Sm2Action) {
      throw ArgumentError.value(action, 'action', 'not an sm2 action');
    }
    final (ease, interval, repetitions) = _valuesOf(state);
    if (state.learnedAt == null) {
      throw ArgumentError.value(state, 'state', 'a card still learning');
    }
    final nextEase = _nextEase(ease, action);
    final passed = _qualityOf[action]! >= _passingQuality;
    final nextInterval = passed
        ? _passedInterval(interval, repetitions, nextEase)
        : _firstIntervalDays;
    final dueAt = dueAtLocalMidnight(now, nextInterval);
    final lapses = isLapse(action) ? 1 : 0;
    return (
      state.copyWith(
        easeFactor: nextEase,
        intervalDays: nextInterval,
        repetitions: passed ? repetitions + 1 : 0,
        dueAt: dueAt,
        lastAnsweredAt: now,
        answerCount: state.answerCount + 1,
        lapseCount: state.lapseCount + lapses,
      ),
      ReviewLogEntry(
        kind: ReviewKind.scheduled,
        previousEaseFactor: ease,
        nextEaseFactor: nextEase,
        previousIntervalDays: interval,
        nextIntervalDays: nextInterval,
        nextDueAt: dueAt,
      ),
    );
  }

  /// Interval 1 with one repetition, so the first `good` of a review gives
  /// 6 days; the ease stays as it is (BR-STUDY-053; spec D6).
  @override
  CardScheduleState learned(CardScheduleState state, DateTime now) {
    _valuesOf(state);
    if (state.learnedAt != null) {
      throw ArgumentError.value(state, 'state', 'a card already learned');
    }
    return state.copyWith(
      learnedAt: now,
      intervalDays: _firstIntervalDays,
      repetitions: 1,
      dueAt: dueAtLocalMidnight(now, _firstIntervalDays),
    );
  }

  (double, int, int) _valuesOf(CardScheduleState state) {
    final ease = state.easeFactor;
    final interval = state.intervalDays;
    final repetitions = state.repetitions;
    if (ease == null || interval == null || repetitions == null) {
      throw ArgumentError.value(state, 'state', 'not an sm2 state');
    }
    return (ease, interval, repetitions);
  }

  int _passedInterval(int interval, int repetitions, double ease) =>
      switch (repetitions) {
        0 => _firstIntervalDays,
        1 => _secondIntervalDays,
        _ => (interval * ease).round(),
      };

  double _nextEase(double ease, Sm2Action action) {
    final distance = _perfectQuality - _qualityOf[action]!;
    final change = 0.1 - distance * (0.08 + distance * 0.02);
    return math.max(_minEase, ease + change);
  }
}

const Sm2Scheduler sm2Scheduler = Sm2Scheduler();

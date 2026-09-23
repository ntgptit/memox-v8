import 'dart:math' as math;

import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';

/// SM-2's quality `q` of each action, as this plan maps it (Clarification 15
/// of the foundation plan records BR-SRS-010's mapping).
const _qualityOf = {
  Sm2Action.again: 2,
  Sm2Action.hard: 3,
  Sm2Action.good: 4,
  Sm2Action.easy: 5,
};
const _perfectQuality = 5;
const _minEase = 1.3;
const _firstIntervalDays = 1;
const _secondIntervalDays = 6;

typedef _Step = (CardScheduleState, ReviewLogEntry);

/// The `sm2` scheduler: classic SM-2 with a 1.3 ease floor.
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
  (CardScheduleState, ReviewLogEntry) next(
    CardScheduleState state,
    Object action,
    DateTime now,
  ) {
    if (action is! Sm2Action) {
      throw ArgumentError.value(action, 'action', 'not an sm2 action');
    }
    final ease = state.easeFactor;
    final interval = state.intervalDays;
    final repetitions = state.repetitions;
    if (ease == null || interval == null || repetitions == null) {
      throw ArgumentError.value(state, 'state', 'not an sm2 state');
    }
    final answered = state.copyWith(lastAnsweredAt: now);
    if (state.learnedAt == null) {
      return _learning(answered, action, ease, interval, now);
    }
    if (action == Sm2Action.again) return _relearning(answered, ease, interval);
    return _scheduled(answered, action, ease, interval, repetitions, now);
  }

  /// Before the card is learned: `good`/`easy` learn it at a one-day
  /// interval, `again` restarts its repetitions, `hard` only moves the ease.
  _Step _learning(
    CardScheduleState state,
    Sm2Action action,
    double ease,
    int interval,
    DateTime now,
  ) {
    final nextEase = _nextEase(ease, action);
    final next = switch (action) {
      Sm2Action.again => state.copyWith(easeFactor: nextEase, repetitions: 0),
      Sm2Action.hard => state.copyWith(easeFactor: nextEase),
      Sm2Action.good || Sm2Action.easy => state.copyWith(
        learnedAt: now,
        easeFactor: nextEase,
        intervalDays: _firstIntervalDays,
        repetitions: 1,
      ),
    };
    return (
      next,
      ReviewLogEntry(
        kind: ReviewKind.learning,
        previousEaseFactor: ease,
        nextEaseFactor: nextEase,
        previousIntervalDays: interval,
        nextIntervalDays: next.intervalDays,
      ),
    );
  }

  /// A learned card answered `hard`/`good`/`easy`: 1 day, then 6, then the
  /// interval times the new ease, due at local midnight (BR-STUDY-074).
  _Step _scheduled(
    CardScheduleState state,
    Sm2Action action,
    double ease,
    int interval,
    int repetitions,
    DateTime now,
  ) {
    final nextEase = _nextEase(ease, action);
    final nextInterval = switch (repetitions) {
      0 => _firstIntervalDays,
      1 => _secondIntervalDays,
      _ => (interval * nextEase).round(),
    };
    final dueAt = dueAtLocalMidnight(now, nextInterval);
    return (
      state.copyWith(
        easeFactor: nextEase,
        intervalDays: nextInterval,
        repetitions: repetitions + 1,
        dueAt: dueAt,
        answerCount: state.answerCount + 1,
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

  /// A learned card answered `again`: ease, interval and due date unchanged
  /// (BR-SRS-017), repetitions start over, one more lapse (BR-SRS-018).
  _Step _relearning(CardScheduleState state, double ease, int interval) => (
    state.copyWith(repetitions: 0, lapseCount: state.lapseCount + 1),
    ReviewLogEntry(
      kind: ReviewKind.relearning,
      previousEaseFactor: ease,
      nextEaseFactor: ease,
      previousIntervalDays: interval,
      nextIntervalDays: interval,
      nextDueAt: state.dueAt,
    ),
  );

  double _nextEase(double ease, Sm2Action action) {
    final distance = _perfectQuality - _qualityOf[action]!;
    final change = 0.1 - distance * (0.08 + distance * 0.02);
    return math.max(_minEase, ease + change);
  }
}

const Sm2Scheduler sm2Scheduler = Sm2Scheduler();

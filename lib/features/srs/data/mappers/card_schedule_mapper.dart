import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// The `card_schedule` columns of [state] under [type] at [version]; the
/// card id is the caller's.
CardScheduleCompanion cardScheduleColumnsOf(
  CardScheduleState state, {
  required SchedulerType type,
  required int version,
}) => CardScheduleCompanion(
  schedulerType: Value(type.code),
  schedulerVersion: Value(version),
  generation: Value(state.generation),
  learnedAt: Value(state.learnedAt),
  dueAt: Value(state.dueAt),
  lastAnsweredAt: Value(state.lastAnsweredAt),
  answerCount: Value(state.answerCount),
  lapseCount: Value(state.lapseCount),
  currentBox: Value(state.currentBox),
  easeFactor: Value(state.easeFactor),
  intervalDays: Value(state.intervalDays),
  repetitions: Value(state.repetitions),
);

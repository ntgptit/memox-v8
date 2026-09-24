import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// A pure function of (state, action, now) -> (next state, log entry). Time
/// is injected so tests never depend on the wall clock (spec §5 "SRS core").
abstract interface class SrsScheduler {
  SchedulerType get type;
  int get version;
  Set<Object> get supportedActions;
  (CardScheduleState, ReviewLogEntry) next(
    CardScheduleState state,
    Object action,
    DateTime now,
  );
}

import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// The schedule of a learned card, as pure functions of (state, action, now).
/// Time is injected so tests never depend on the wall clock (spec §5 "SRS
/// core"). Only a `scheduled` turn reaches [next]: the session decides a
/// turn's kind (BR-SRS-015), and `learning` and `relearning` turns leave the
/// schedule as it is (BR-SRS-017, BR-STUDY-053).
abstract interface class SrsScheduler {
  SchedulerType get type;
  int get version;
  Set<Object> get supportedActions;

  /// Whether [action] says the card was not remembered: `forgotten` or
  /// `again` (BR-SRS-018, BR-STUDY-005, BR-STUDY-007).
  bool isLapse(Object action);

  /// A `scheduled` turn on a learned card (BR-SRS-016). A card still learning
  /// is a programming error and throws [ArgumentError].
  (CardScheduleState, ReviewLogEntry) next(
    CardScheduleState state,
    Object action,
    DateTime now,
  );

  /// The schedule a card starts when it finishes learning (BR-STUDY-053):
  /// learned at [now], at the lowest level, due at the next local midnight
  /// (BR-STUDY-074). A learned card is a programming error and throws
  /// [ArgumentError].
  CardScheduleState learned(CardScheduleState state, DateTime now);
}

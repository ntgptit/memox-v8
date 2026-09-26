import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';

/// What each action of [scheduler] would set [state]'s interval to if the
/// card were answered at [now]: the write's own `next`, so the preview and
/// the write cannot fork (FE-A6 D11, handoff 16a). Keyed by action, in
/// `supportedActions` order; nothing is written.
Map<Object, int> nextIntervalsOf(
  SrsScheduler scheduler,
  CardScheduleState state,
  DateTime now,
) => {
  for (final action in scheduler.supportedActions)
    action: ?scheduler.next(state, action, now).$2.nextIntervalDays,
};

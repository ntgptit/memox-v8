import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';

/// The lookup table behind "scheduler is chosen per root deck" (spec §5).
SrsScheduler schedulerFor(SchedulerType type) => switch (type) {
  SchedulerType.eightBox => eightBoxScheduler,
  SchedulerType.sm2 => sm2Scheduler,
};

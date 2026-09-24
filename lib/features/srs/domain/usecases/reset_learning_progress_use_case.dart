import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

/// UC-SRS-001 steps 3 to 5: clears the learning progress of a root's tree in
/// one transaction, keeping its scheduler or switching to [schedulerType]
/// (BR-SRS-020 to BR-SRS-027, BR-STUDY-015).
final class ResetLearningProgressUseCase {
  const ResetLearningProgressUseCase(this._schedules);

  final ScheduleRepository _schedules;

  Future<Outcome<void, SrsRejection>> call({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) => _schedules.resetLearning(
    rootDeckId: rootDeckId,
    schedulerType: schedulerType,
  );
}

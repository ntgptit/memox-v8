import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

/// UC-DECK-002: another scheduler for a root deck no card of which has been
/// answered yet (BR-SRS-002, BR-SRS-004); its open sessions end
/// (BR-STUDY-016).
final class ChangeDeckSchedulerUseCase {
  const ChangeDeckSchedulerUseCase(this._schedules);

  final ScheduleRepository _schedules;

  Future<Outcome<void, SrsRejection>> call({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) => _schedules.changeScheduler(
    rootDeckId: rootDeckId,
    newType: schedulerType,
  );
}

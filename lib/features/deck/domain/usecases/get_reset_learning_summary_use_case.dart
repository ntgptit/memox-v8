import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

/// UC-SRS-001 step 2: what a reset would clear, for its confirmation
/// (BR-SRS-030), including whether there is anything to lose (A2).
final class GetResetLearningSummaryUseCase {
  const GetResetLearningSummaryUseCase(this._schedules);

  final ScheduleRepository _schedules;

  Future<Outcome<ResetLearningSummary, SrsRejection>> call({
    required String rootDeckId,
  }) => _schedules.resetSummary(rootDeckId: rootDeckId);
}

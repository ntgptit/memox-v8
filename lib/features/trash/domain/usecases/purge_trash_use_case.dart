import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// UC-TRASH-001 A3: the batches the person chose, and every expired one, go
/// for good; a batch that still holds another is skipped and reported
/// (BR-TRASH-010, E4, E6).
final class PurgeTrashUseCase {
  const PurgeTrashUseCase(this._trash, this._clock);

  final TrashRepository _trash;
  final DayClock _clock;

  Future<PurgeReport> call({required Set<String> batchIds}) =>
      _trash.purge(batchIds: batchIds, now: _clock.now());
}

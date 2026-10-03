import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';
import 'package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart';

/// UC-TRASH-001 A3: the batches the person chose go for good, and so does
/// every batch expired by the purge clock (BR-TRASH-009, R10). Without a
/// server time (never synced) nothing counts as expired and only the chosen
/// batches go. A batch that still holds another is skipped and reported
/// (BR-TRASH-010, E4, E6).
final class PurgeTrashUseCase {
  const PurgeTrashUseCase(this._trash, this._clock, this._serverTime);

  final TrashRepository _trash;
  final DayClock _clock;
  final ServerTimeReader _serverTime;

  /// A time before every batch: its cutoff takes none of the expired ones.
  static final _beforeEveryBatch = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  Future<PurgeReport> call({required Set<String> batchIds}) async {
    final now = trashPurgeClock(_clock.now(), await _serverTime());
    return _trash.purge(batchIds: batchIds, now: now ?? _beforeEveryBatch);
  }
}

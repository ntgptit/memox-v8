import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// UC-TRASH-001 step 3 and A4: every batch 720 hours old or more goes for
/// good. The UI calls it at start, on resume, when the Trash opens and when
/// it regains focus (BR-TRASH-009; trash spec D13).
final class PurgeExpiredTrashUseCase {
  const PurgeExpiredTrashUseCase(this._trash, this._clock);

  final TrashRepository _trash;
  final DayClock _clock;

  Future<PurgeReport> call() => _trash.purgeExpired(now: _clock.now());
}

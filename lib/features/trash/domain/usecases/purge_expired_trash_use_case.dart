import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// The server's time as of the last sync, or null when this device never
/// synced or its server sends none (BR-TRASH-009, R10).
typedef ServerTimeReader = Future<DateTime?> Function();

/// What a purge that waits reports: nothing was touched.
const _waits = PurgeReport(purged: {}, blocked: {}, missing: {});

/// UC-TRASH-001 step 3 and A4: every batch 720 hours old or more goes for
/// good, by the purge clock: the earlier of the device clock and the server
/// time seen at the last sync. Without a server time it waits and deletes
/// nothing (BR-TRASH-009, R10). The UI calls it at start, on resume, when
/// the Trash opens and when it regains focus (trash spec D13).
final class PurgeExpiredTrashUseCase {
  const PurgeExpiredTrashUseCase(this._trash, this._clock, this._serverTime);

  final TrashRepository _trash;
  final DayClock _clock;
  final ServerTimeReader _serverTime;

  Future<PurgeReport> call() async {
    final now = trashPurgeClock(_clock.now(), await _serverTime());
    if (now == null) return _waits;
    return _trash.purgeExpired(now: now);
  }
}

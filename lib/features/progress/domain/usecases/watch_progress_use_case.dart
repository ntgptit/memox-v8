import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

/// UC-PROGRESS-001, and UC-PROGRESS-002 at the library level: `/progress`,
/// again on every write it can see and at every local midnight, when the
/// window slides a day, Today returns to 0 and the streak takes its held
/// branch, with no write. Each day reads the clock and its offset once
/// (BR-PROGRESS-013, BR-PROGRESS-018; Progress spec §7, D4).
final class WatchProgressUseCase {
  const WatchProgressUseCase(this._progress, this._clock);

  final ProgressRepository _progress;
  final DayClock _clock;

  Stream<Progress> call() => watchEachLocalDay(
    _clock,
    (now) => _progress.watchProgress(ProgressDays.of(now, now.timeZoneOffset)),
  );
}

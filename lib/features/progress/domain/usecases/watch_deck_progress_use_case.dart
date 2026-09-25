import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

/// UC-PROGRESS-002 at a deck's level: `/progress/:deckId`, again on every
/// write it can see and at every local midnight, with no write
/// (BR-PROGRESS-008; UC-PROGRESS-002 A4; Progress spec §7, D4).
final class WatchDeckProgressUseCase {
  const WatchDeckProgressUseCase(this._progress, this._clock);

  final ProgressRepository _progress;
  final DayClock _clock;

  Stream<DeckProgress> call(String deckId) => watchEachLocalDay(
    _clock,
    (now) => _progress.watchDeckProgress(
      deckId: deckId,
      days: ProgressDays.of(now, now.timeZoneOffset),
    ),
  );
}

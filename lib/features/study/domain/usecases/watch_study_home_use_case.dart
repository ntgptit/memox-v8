import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';

/// UC-STUDY-002: the Study tab, again on every write it can see and at every
/// local midnight, when Due today becomes Overdue and yesterday's session is
/// no longer offered, with no write (BR-STUDY-068, BR-STUDY-075; Study Home
/// spec §7).
final class WatchStudyHomeUseCase {
  const WatchStudyHomeUseCase(this._home, this._clock);

  final StudyHomeRepository _home;
  final DayClock _clock;

  Stream<StudyHome> call() => watchEachLocalDay(
    _clock,
    (now) => _home.watchHome(now: now, startOfToday: startOfLocalDay(now)),
  );
}

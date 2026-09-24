import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';

/// UC-STUDY-001 steps 1–2 and 4: the Study Entry of a deck, again on every
/// change and at every local midnight, when cards fall due and "today"
/// moves with no write (BR-STUDY-067, BR-STUDY-072); notFound once the deck
/// is gone (E1). It writes nothing (BR-STUDY-075).
final class WatchStudyEntryUseCase {
  const WatchStudyEntryUseCase(this._entries, this._clock);

  final StudyEntryRepository _entries;
  final DayClock _clock;

  Stream<Outcome<StudyEntry, StudyRejection>> call({required String deckId}) =>
      watchEachLocalDay(
        _clock,
        (now) => _entries
            .watchEntry(deckId: deckId, now: now)
            .map<Outcome<StudyEntry, StudyRejection>>(
              (entry) => switch (entry) {
                final StudyEntry entry => Ok(entry),
                null => const Rejected(StudyRejection.notFound),
              },
            ),
      );
}

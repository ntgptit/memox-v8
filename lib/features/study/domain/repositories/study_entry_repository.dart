import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The one implementation is `StudyEntryRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class StudyEntryRepository {
  /// UC-STUDY-001 steps 3 and 5: a learning session on the new cards of
  /// [deckId] and its whole subtree (BR-STUDY-051), at most `card_limit` of
  /// them chosen by `new_card_order` (BR-STUDY-003, BR-STUDY-057), with round
  /// 1 of every stage it runs (BR-STUDY-021, BR-STUDY-022). It closes the
  /// app's open session first (BR-STUDY-072; spec D2). Answers the session's
  /// id; notFound for a deck that is gone or in the Trash, nothingToLearn when
  /// no card is new, and a refusal writes nothing.
  Future<Outcome<String, StudyRejection>> openLearningSession({
    required String deckId,
    DateTime? now,
  });

  /// UC-STUDY-001 step 4 and UC-STUDY-003: a review in [mode] on the due
  /// cards of [deckId] and its whole subtree, at most `card_limit` of them,
  /// earliest due first (BR-STUDY-002, BR-STUDY-003, BR-STUDY-051). [mode]
  /// must be a review mode of the root's algorithm (modeNotOffered,
  /// BR-STUDY-055) that can run on those cards (modeUnavailable,
  /// BR-MODE-009); [direction] must be given exactly when BR-MODE-013 takes
  /// one (directionRequired, directionNotAllowed, BR-MODE-018). nothingDue
  /// when no card is due (BR-STUDY-054). It closes the app's open session
  /// first (spec D2); a refusal writes nothing.
  Future<Outcome<String, StudyRejection>> openReviewSession({
    required String deckId,
    required StudyMode mode,
    DirectionChoice? direction,
    DateTime? now,
  });

  /// UC-STUDY-001 steps 1–2 and 4 (spec §8.1): the Study Entry of [deckId]
  /// at [now], again on every write it can see; null once the deck is gone
  /// or in the Trash. It writes nothing (BR-STUDY-075).
  Stream<StudyEntry?> watchEntry({
    required String deckId,
    required DateTime now,
  });
}

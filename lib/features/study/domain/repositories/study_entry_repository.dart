import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';

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
}

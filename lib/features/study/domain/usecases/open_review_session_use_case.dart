import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// UC-STUDY-001 step 4 and UC-STUDY-003 step 5: Review in the mode picked,
/// with the direction chosen when the mode takes one (BR-MODE-013). Answers
/// the new session's id.
final class OpenReviewSessionUseCase {
  const OpenReviewSessionUseCase(this._entries);

  final StudyEntryRepository _entries;

  Future<Outcome<String, StudyRejection>> call({
    required String deckId,
    required StudyMode mode,
    DirectionChoice? direction,
  }) => _entries.openReviewSession(
    deckId: deckId,
    mode: mode,
    direction: direction,
  );
}

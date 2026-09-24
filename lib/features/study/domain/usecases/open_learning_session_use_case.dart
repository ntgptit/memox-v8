import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';

/// UC-STUDY-001 step 3: Learn new, the only way a learning session is
/// created (BR-STUDY-020). Answers the new session's id.
final class OpenLearningSessionUseCase {
  const OpenLearningSessionUseCase(this._entries);

  final StudyEntryRepository _entries;

  Future<Outcome<String, StudyRejection>> call({required String deckId}) =>
      _entries.openLearningSession(deckId: deckId);
}

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// UC-STUDY-001 A3: ✕ leaves the session for good; its turns stay
/// (BR-STUDY-014, BR-STUDY-019).
final class AbandonStudySessionUseCase {
  const AbandonStudySessionUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<Outcome<void, StudyRejection>> call({required String sessionId}) =>
      _sessions.abandonSession(sessionId: sessionId);
}

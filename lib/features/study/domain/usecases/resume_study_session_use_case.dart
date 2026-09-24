import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// UC-STUDY-001 A3b: Continue, on a session of the current local day
/// (BR-STUDY-072). A session of an earlier day, or one whose root was reset,
/// is closed and refused.
final class ResumeStudySessionUseCase {
  const ResumeStudySessionUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<Outcome<void, StudyRejection>> call({required String sessionId}) =>
      _sessions.resumeSession(sessionId: sessionId);
}

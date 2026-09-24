import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// UC-STUDY-001 steps 6–13: the session screen, again after every turn, and
/// notFound once the session is gone with its deck (A5, E5). It writes
/// nothing (BR-STUDY-075).
final class WatchStudySessionUseCase {
  const WatchStudySessionUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Stream<Outcome<StudySessionView, StudyRejection>> call({
    required String sessionId,
  }) => _sessions
      .watchSession(sessionId)
      .map<Outcome<StudySessionView, StudyRejection>>(
        (view) => switch (view) {
          final StudySessionView view => Ok(view),
          null => const Rejected(StudyRejection.notFound),
        },
      );
}

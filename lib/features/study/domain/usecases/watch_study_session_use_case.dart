import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_view_repository.dart';

/// UC-STUDY-001 steps 6–13: the session screen, again after every turn, and
/// notFound once its deck is in the Trash or the session is gone (A5, E5;
/// BR-TRASH-002). It writes nothing (BR-STUDY-075).
final class WatchStudySessionUseCase {
  const WatchStudySessionUseCase(this._sessions);

  final StudySessionViewRepository _sessions;

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

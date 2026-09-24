import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// UC-STUDY-001 steps 6–13: [call] answers the card the session serves. A
/// busy database writes nothing, and the person retries the same answer
/// (E2, BR-STUDY-004). Any other database failure has rolled the turn back;
/// the session is then closed as `failed` in a write of its own, and the
/// failure reaches the UI (E3, BR-STUDY-018; spec D9).
final class AnswerStudyTurnUseCase {
  const AnswerStudyTurnUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<Outcome<void, StudyRejection>> call({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
  }) async {
    try {
      return await _sessions.answerTurn(
        sessionId: sessionId,
        cardId: cardId,
        answer: answer,
      );
    } on DatabaseLockedFailure {
      rethrow;
    } on Failure catch (failure, stackTrace) {
      await _close(sessionId);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> _close(String sessionId) async {
    try {
      await _sessions.failSession(sessionId: sessionId);
    } on Failure {
      // The storage that failed the turn failed this write as well. The
      // person sees the turn's failure; the session stays in_progress, so
      // Continue meets the same storage, and abandonStaleSessions closes it
      // on a later day (spec §8.3).
    }
  }
}

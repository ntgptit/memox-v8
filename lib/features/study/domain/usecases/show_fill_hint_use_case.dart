import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// `fill`: the person asks for the card's hint. The turn records that it was
/// shown, and its result does not change (BR-STUDY-028; graded modes spec
/// §8.3).
final class ShowFillHintUseCase {
  const ShowFillHintUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<Outcome<void, StudyRejection>> call({
    required String sessionId,
    required String cardId,
  }) => _sessions.showFillHint(sessionId: sessionId, cardId: cardId);
}

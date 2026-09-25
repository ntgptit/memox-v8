import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';

/// `recall`: the person shows the answer before the time runs out. Nothing
/// is recorded; the time stops, and the turn waits for the person's
/// self-assessment (BR-STUDY-065, BR-STUDY-036; graded modes spec §8.3).
final class RevealRecallAnswerUseCase {
  const RevealRecallAnswerUseCase(this._sessions);

  final StudySessionRepository _sessions;

  /// [remainingMs] outside 0 to [recallTurnMs] is a bug in the caller: an
  /// `ArgumentError`, before any write.
  Future<Outcome<void, StudyRejection>> call({
    required String sessionId,
    required String cardId,
    required int remainingMs,
  }) {
    RangeError.checkValueInInterval(
      remainingMs,
      0,
      recallTurnMs,
      'remainingMs',
    );
    return _sessions.revealRecallAnswer(
      sessionId: sessionId,
      cardId: cardId,
      remainingMs: remainingMs,
    );
  }
}

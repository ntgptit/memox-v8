import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';

/// `recall`: the time left of the turn, kept so Continue takes it up where it
/// stopped. The screen saves it when the app goes to the background and when
/// the screen closes, not on every tick (BR-STUDY-036; graded modes spec
/// §8.3).
final class SaveRecallTimeUseCase {
  const SaveRecallTimeUseCase(this._sessions);

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
    return _sessions.saveRecallTime(
      sessionId: sessionId,
      cardId: cardId,
      remainingMs: remainingMs,
    );
  }
}

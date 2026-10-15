import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// UC-TOPIK-003: go to another question; the time of the one left is kept
/// (BR-TOPIK-015).
final class MoveTopikQuestionUseCase {
  const MoveTopikQuestionUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Future<Outcome<void, TopikRejection>> call({
    required String attemptId,
    required int toQuestionNo,
    required int elapsedMs,
  }) => _attempts.move(
    attemptId: attemptId,
    toQuestionNo: toQuestionNo,
    elapsedMs: elapsedMs,
  );
}

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// Delete an attempt, confirmed by the screen (BR-TOPIK-018).
final class DeleteTopikAttemptUseCase {
  const DeleteTopikAttemptUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Future<Outcome<void, TopikRejection>> call(String attemptId) =>
      _attempts.delete(attemptId);
}

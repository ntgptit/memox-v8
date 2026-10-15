import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// UC-TOPIK-003: background or exit; the current question keeps its time
/// (BR-TOPIK-015).
final class RecordTopikTimeUseCase {
  const RecordTopikTimeUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Future<Outcome<void, TopikRejection>> call({
    required String attemptId,
    required int elapsedMs,
  }) => _attempts.recordTime(attemptId: attemptId, elapsedMs: elapsedMs);
}

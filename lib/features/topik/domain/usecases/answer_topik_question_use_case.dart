import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// UC-TOPIK-003: choose an option, replacing an earlier one (BR-TOPIK-012).
final class AnswerTopikQuestionUseCase {
  const AnswerTopikQuestionUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Future<Outcome<void, TopikRejection>> call({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required int elapsedMs,
  }) => _attempts.answer(
    attemptId: attemptId,
    questionNo: questionNo,
    selectedIdx: selectedIdx,
    elapsedMs: elapsedMs,
  );
}

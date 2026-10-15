import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-003 submit: scored against the content at submit
/// (BR-TOPIK-013); refused when that content is gone (BR-TOPIK-019).
final class SubmitTopikAttemptUseCase {
  const SubmitTopikAttemptUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Future<Outcome<TopikAttempt, TopikRejection>> call({
    required String attemptId,
    required String testId,
    required int elapsedMs,
  }) async {
    final test = await topikTestIn(_content, testId);
    if (test == null) return const Rejected(TopikRejection.testUnavailable);
    return _attempts.submit(
      attemptId: attemptId,
      test: test,
      elapsedMs: elapsedMs,
    );
  }
}

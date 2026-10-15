import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-003 start: a new attempt of a valid test; with
/// [replaceInProgress] (Start new, confirmed) the attempt in progress is
/// replaced in one write (BR-TOPIK-010, BR-TOPIK-011, BR-TOPIK-019).
final class StartTopikAttemptUseCase {
  const StartTopikAttemptUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Future<Outcome<TopikAttempt, TopikRejection>> call(
    String testId, {
    bool replaceInProgress = false,
  }) async {
    final test = await topikTestIn(_content, testId);
    if (test == null) return const Rejected(TopikRejection.testUnavailable);
    if (replaceInProgress) {
      return Ok(await _attempts.replaceInProgressAndStart(test));
    }
    return _attempts.start(test);
  }
}

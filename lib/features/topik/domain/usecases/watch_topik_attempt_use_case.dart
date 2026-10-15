import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-003: the attempt with its answers and its test; null once the
/// attempt is gone (BR-TOPIK-018, BR-TOPIK-027).
final class WatchTopikAttemptUseCase {
  const WatchTopikAttemptUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<TopikAttemptView?> call(String attemptId) => _attempts
      .watchAttempt(attemptId)
      .asyncMap(
        (detail) async => detail == null
            ? null
            : TopikAttemptView(
                detail: detail,
                test: await topikTestIn(_content, detail.attempt.testId),
              ),
      );
}

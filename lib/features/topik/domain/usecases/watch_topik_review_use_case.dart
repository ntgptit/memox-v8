import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-005: the attempt over the current content, flagged when the
/// content changed or is gone (BR-TOPIK-019); null once the attempt is gone.
final class WatchTopikReviewUseCase {
  const WatchTopikReviewUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<TopikReviewView?> call(String attemptId) => _attempts
      .watchAttempt(attemptId)
      .asyncMap(
        (detail) async => detail == null
            ? null
            : TopikReviewView(
                detail: detail,
                test: await topikTestIn(_content, detail.attempt.testId),
              ),
      );
}

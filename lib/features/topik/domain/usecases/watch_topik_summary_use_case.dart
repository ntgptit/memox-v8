import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-004: Summary of a submitted attempt from its snapshot; null
/// when the attempt is gone or not submitted (BR-TOPIK-019, BR-TOPIK-023).
final class WatchTopikSummaryUseCase {
  const WatchTopikSummaryUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<TopikSummaryView?> call(String attemptId) =>
      _attempts.watchAttempt(attemptId).asyncMap((detail) async {
        if (detail == null || !detail.attempt.isCompleted) return null;
        return TopikSummaryView(
          attempt: detail.attempt,
          summary: topikAttemptSummaryOf(detail),
          test: await topikTestIn(_content, detail.attempt.testId),
        );
      });
}

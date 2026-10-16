import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// UC-TOPIK-004: Summary of a submitted attempt from its snapshot alone; null
/// when the attempt is gone or not submitted (BR-TOPIK-019, BR-TOPIK-023).
///
/// It reads no content: a test that changed, left the bundle or cannot be
/// read never touches a past result (BR-TOPIK-019).
final class WatchTopikSummaryUseCase {
  const WatchTopikSummaryUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Stream<TopikSummaryView?> call(String attemptId) =>
      _attempts.watchAttempt(attemptId).map((detail) {
        if (detail == null || !detail.attempt.isCompleted) return null;
        return TopikSummaryView(
          attempt: detail.attempt,
          summary: topikAttemptSummaryOf(detail),
        );
      });
}

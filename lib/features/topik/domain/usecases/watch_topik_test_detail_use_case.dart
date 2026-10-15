import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// UC-TOPIK-002: Overall Progress, Recent Attempts and History of one test.
final class WatchTopikTestDetailUseCase {
  const WatchTopikTestDetailUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<TopikTestDetail> call(String testId) =>
      Stream.fromFuture(topikTestIn(_content, testId)).asyncExpand(
        (test) => _attempts
            .watchAttemptsOfTest(testId)
            .map(
              (attempts) => TopikTestDetail(
                test: test,
                progress: topikTestProgressOf(attempts),
                attempts: topikNumberedAttemptsOf(attempts),
              ),
            ),
      );
}

/// The valid test [testId] of the catalog, or null (BR-TOPIK-019).
Future<TopikTest?> topikTestIn(
  TopikContentRepository content,
  String testId,
) async {
  for (final test in await content.catalog()) {
    if (test.testId == testId) return test;
  }
  return null;
}

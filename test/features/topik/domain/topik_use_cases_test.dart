import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/usecases/answer_topik_question_use_case.dart';
import 'package:memox/features/topik/domain/usecases/delete_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/start_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/submit_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_catalog_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_review_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_summary_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';

// Spec §3.3: one use case per interaction, over the real attempt store.
void main() {
  final content = topikTestFixture();
  late AppDatabase db;
  late TopikAttemptRepositoryImpl attempts;
  late FakeTopikContentRepository catalog;
  setUp(() {
    db = openTestDatabase();
    attempts = TopikAttemptRepositoryImpl(db);
    catalog = FakeTopikContentRepository([content]);
  });
  tearDown(() => db.close());

  test('the catalog carries each test with its status', () async {
    final start = StartTopikAttemptUseCase(catalog, attempts);
    topikOk(await start(content.testId));

    final entries = await WatchTopikCatalogUseCase(catalog, attempts)().first;

    expect(entries.single.test.testId, content.testId);
    expect(entries.single.status!.hasInProgress, isTrue);
  });

  test(
    'Start refuses a test the catalog no longer has (BR-TOPIK-019)',
    () async {
      expect(
        topikReason(await StartTopikAttemptUseCase(catalog, attempts)('gone')),
        TopikRejection.testUnavailable,
      );
    },
  );

  test('Start new replaces the attempt in progress (BR-TOPIK-011)', () async {
    final start = StartTopikAttemptUseCase(catalog, attempts);
    final first = topikOk(await start(content.testId));
    expect(
      topikReason(await start(content.testId)),
      TopikRejection.inProgressExists,
    );
    final second = topikOk(
      await start(content.testId, replaceInProgress: true),
    );
    expect(second.id, isNot(first.id));
  });

  test(
    'the test detail numbers attempts and keeps the one in progress',
    () async {
      final start = StartTopikAttemptUseCase(catalog, attempts);
      final submit = SubmitTopikAttemptUseCase(catalog, attempts);
      final done = topikOk(await start(content.testId));
      topikOk(
        await submit(attemptId: done.id, testId: content.testId, elapsedMs: 0),
      );
      final open = topikOk(await start(content.testId));

      final detail = await WatchTopikTestDetailUseCase(catalog, attempts)(
        content.testId,
      ).first;

      expect(detail.test, isNotNull);
      expect([for (final n in detail.attempts) n.number], [2, 1]);
      expect(detail.inProgress!.attempt.id, open.id);
      expect(detail.progress.sessions, 2);
      expect(detail.recent, hasLength(2));
    },
  );

  test('submit, then summary and review read the attempt', () async {
    final start = StartTopikAttemptUseCase(catalog, attempts);
    final attempt = topikOk(await start(content.testId));
    topikOk(
      await AnswerTopikQuestionUseCase(attempts)(
        attemptId: attempt.id,
        questionNo: 1,
        selectedIdx: 1,
        elapsedMs: 700,
      ),
    );
    final view = await WatchTopikAttemptUseCase(catalog, attempts)(attempt.id)
        .first;
    expect(view!.detail.answers.first.selectedIdx, 1);
    expect(
      await WatchTopikSummaryUseCase(catalog, attempts)(attempt.id).first,
      isNull,
    );

    topikOk(
      await SubmitTopikAttemptUseCase(catalog, attempts)(
        attemptId: attempt.id,
        testId: content.testId,
        elapsedMs: 0,
      ),
    );

    final summary = (await WatchTopikSummaryUseCase(catalog, attempts)(
      attempt.id,
    ).first)!;
    expect(summary.summary.score, 2);
    final review = (await WatchTopikReviewUseCase(catalog, attempts)(attempt.id)
        .first)!;
    expect(review.isContentChanged, isFalse);
    expect(review.isUnavailable, isFalse);
  });

  test('review flags newer content, and an unavailable test', () async {
    final attempt = topikOk(
      await StartTopikAttemptUseCase(catalog, attempts)(content.testId),
    );
    topikOk(
      await SubmitTopikAttemptUseCase(catalog, attempts)(
        attemptId: attempt.id,
        testId: content.testId,
        elapsedMs: 0,
      ),
    );
    final json = topikTestJson()..['contentVersion'] = 2;
    catalog.tests = [topikTestOfFixtureJson(json)];
    final changed = (await WatchTopikReviewUseCase(catalog, attempts)(
      attempt.id,
    ).first)!;
    expect(changed.isContentChanged, isTrue);

    catalog.tests = [];
    final gone = (await WatchTopikReviewUseCase(catalog, attempts)(attempt.id)
        .first)!;
    expect(gone.isUnavailable, isTrue);
    expect(
      (await WatchTopikSummaryUseCase(catalog, attempts)(
        attempt.id,
      ).first)!.summary.score,
      0,
    );
  });

  test('submit refuses when the test is unavailable; delete removes', () async {
    final attempt = topikOk(
      await StartTopikAttemptUseCase(catalog, attempts)(content.testId),
    );
    catalog.tests = [];
    expect(
      topikReason(
        await SubmitTopikAttemptUseCase(catalog, attempts)(
          attemptId: attempt.id,
          testId: content.testId,
          elapsedMs: 0,
        ),
      ),
      TopikRejection.testUnavailable,
    );
    topikOk(await DeleteTopikAttemptUseCase(attempts)(attempt.id));
    expect(
      await WatchTopikAttemptUseCase(catalog, attempts)(attempt.id).first,
      isNull,
    );
  });
}

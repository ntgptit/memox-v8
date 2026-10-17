import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
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

  test('the catalog and the detail follow every later write', () async {
    final start = StartTopikAttemptUseCase(catalog, attempts);
    final submit = SubmitTopikAttemptUseCase(catalog, attempts);
    final listed = <List<TopikCatalogEntry>>[];
    final details = <TopikTestDetail>[];
    final subscriptions = [
      WatchTopikCatalogUseCase(catalog, attempts)().listen(listed.add),
      WatchTopikTestDetailUseCase(catalog, attempts)(content.testId)
          .listen(details.add),
    ];
    addTearDown(() async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    });
    await pumpEventQueue();
    expect(listed.last.single.status, isNull);
    expect(details.last.attempts, isEmpty);

    final first = topikOk(await start(content.testId));
    topikOk(
      await submit(attemptId: first.id, testId: content.testId, elapsedMs: 0),
    );
    final second = topikOk(await start(content.testId));
    await pumpEventQueue();
    expect(listed.last.single.status!.hasInProgress, isTrue);
    expect(listed.last.single.status!.completedCount, 1);
    expect(
      [for (final n in details.last.attempts) (n.attempt.id, n.number)],
      [(second.id, 2), (first.id, 1)],
    );

    topikOk(await DeleteTopikAttemptUseCase(attempts)(first.id));
    await pumpEventQueue();
    expect(
      [for (final n in details.last.attempts) (n.attempt.id, n.number)],
      [(second.id, 1)],
    );
    expect(details.last.progress.sessions, 1);
    // The list's status follows the delete too (UC-TOPIK-001 A2).
    expect(listed.last.single.status!.completedCount, 0);
    expect(listed.last.single.status!.bestScore, isNull);
    expect(listed.last.single.status!.hasInProgress, isTrue);
  });

  test('the detail and the attempt still stream once the test is gone '
      '(BR-TOPIK-019)', () async {
    final attempt = topikOk(
      await StartTopikAttemptUseCase(catalog, attempts)(content.testId),
    );
    catalog.tests = [];

    final detail = await WatchTopikTestDetailUseCase(catalog, attempts)(
      content.testId,
    ).first;
    final view = (await WatchTopikAttemptUseCase(catalog, attempts)(attempt.id)
        .first)!;

    expect(detail.test, isNull);
    expect(detail.inProgress!.attempt.id, attempt.id);
    expect(view.test, isNull);
    expect(view.detail.attempt.id, attempt.id);
  });

  test(
    'a catalog read that fails reaches the screen, and Retry recovers',
    () async {
      catalog.failure = StateError('asset bundle');
      await expectLater(
        WatchTopikCatalogUseCase(catalog, attempts)(),
        emitsError(isStateError),
      );

      catalog.failure = null;
      final entries = await WatchTopikCatalogUseCase(catalog, attempts)().first;
      expect(entries.single.test.testId, content.testId);
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
    expect(await WatchTopikSummaryUseCase(attempts)(attempt.id).first, isNull);

    topikOk(
      await SubmitTopikAttemptUseCase(catalog, attempts)(
        attemptId: attempt.id,
        testId: content.testId,
        elapsedMs: 0,
      ),
    );

    final summary = (await WatchTopikSummaryUseCase(attempts)(attempt.id)
        .first)!;
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
      (await WatchTopikSummaryUseCase(attempts)(
        attempt.id,
      ).first)!.summary.score,
      0,
    );
  });

  test('the summary reads from the snapshot alone: a content read that fails '
      'changes nothing (BR-TOPIK-019)', () async {
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
    catalog.failure = StateError('the asset bundle cannot be read');

    final summary = (await WatchTopikSummaryUseCase(attempts)(attempt.id)
        .first)!;

    expect(summary.summary.score, 0);
    expect(summary.attempt.id, attempt.id);
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

  test(
    'the attempt view says when its content is missing (BR-TOPIK-019)',
    () async {
      final attempt = topikOk(
        await StartTopikAttemptUseCase(catalog, attempts)(content.testId),
      );
      final watch = WatchTopikAttemptUseCase(catalog, attempts);

      final view = (await watch(attempt.id).first)!;
      expect(view.isContentMissing, isFalse);
      // The test's questions are no longer the attempt's (a content change the
      // validator lets through would show this way).
      final fewer = TopikAttemptView(
        detail: TopikAttemptDetail(
          attempt: view.detail.attempt,
          answers: view.detail.answers.skip(1).toList(),
        ),
        test: view.test,
      );
      expect(fewer.isContentMissing, isTrue);
      catalog.tests = [];
      expect((await watch(attempt.id).first)!.isContentMissing, isTrue);
    },
  );
}

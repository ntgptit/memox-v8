import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart';
import 'package:memox/features/srs/domain/usecases/reset_learning_progress_use_case.dart';

import '../../../support/test_database.dart';

// UC-SRS-001 through its two use cases: the confirmation's summary, then the
// reset that picks another scheduler.

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl schedules;
  setUp(() async {
    db = openTestDatabase();
    schedules = ScheduleRepositoryImpl(db, now: () => DateTime(2026, 9, 24));
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      'created_at, updated_at) VALUES '
      "('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0), "
      "('leaf', 'leaf', 'r', 'r', 2, 'card', NULL, NULL, NULL, 0, 0, 0)",
    );
    await db.customStatement(
      'INSERT INTO card (id, deck_id, front, back, created_at, updated_at) '
      "VALUES ('c', 'leaf', 'f', 'b', 0, 0)",
    );
    await schedules.initializeCard(cardId: 'c');
    await db.customStatement(
      'INSERT INTO study_session (id, deck_id, root_id, generation, '
      'session_kind, current_mode, status, cursor, card_limit, started_at) '
      "VALUES ('s', 'r', 'r', 1, 'learning', 'self_assess', 'in_progress', "
      '0, 20, 0)',
    );
    await schedules.recordReview(
      cardId: 'c',
      sessionId: 's',
      action: EightBoxAction.remembered,
    );
  });
  tearDown(() => db.close());

  Matcher summaryWith(
    SchedulerType schedulerType, {
    required bool isSchedulerLocked,
    required bool hasProgressToLose,
  }) => isA<Ok<ResetLearningSummary, SrsRejection>>().having(
    (ok) => (
      ok.value.schedulerType,
      ok.value.isSchedulerLocked,
      ok.value.hasProgressToLose,
    ),
    'summary',
    (schedulerType, isSchedulerLocked, hasProgressToLose),
  );

  test('the confirmation shows what a locked tree would lose, and the reset '
      'switches it to sm2 with nothing left to lose (UC-SRS-001)', () async {
    final summary = GetResetLearningSummaryUseCase(schedules);

    final before = await summary(rootDeckId: 'r');
    final reset = await ResetLearningProgressUseCase(schedules)(
      rootDeckId: 'r',
      schedulerType: SchedulerType.sm2,
    );
    final after = await summary(rootDeckId: 'r');

    expect(
      before,
      summaryWith(
        SchedulerType.eightBox,
        isSchedulerLocked: true,
        hasProgressToLose: true,
      ),
    );
    expect(reset, isA<Ok<void, SrsRejection>>());
    expect(
      after,
      summaryWith(
        SchedulerType.sm2,
        isSchedulerLocked: false,
        hasProgressToLose: false,
      ),
    );
  });

  test('a sub-deck has no reset (UC-SRS-001 A4)', () async {
    final result = await ResetLearningProgressUseCase(schedules)(
      rootDeckId: 'leaf',
    );

    expect(
      result,
      isA<Rejected<void, SrsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SrsRejection.notARootDeck,
      ),
    );
  });
}

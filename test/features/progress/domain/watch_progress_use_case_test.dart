import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/usecases/watch_deck_progress_use_case.dart';
import 'package:memox/features/progress/domain/usecases/watch_progress_use_case.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-PROGRESS-001 A4 and UC-PROGRESS-002 A4: the Progress screen across a
// local midnight (BR-PROGRESS-018; Progress spec §7). Times are local.

void main() {
  late AppDatabase db;
  late String lessonId;
  final evening = DateTime(2026, 9, 25, 21);

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: () => evening);
    final korean = await decks.root('Korean');
    lessonId = (await decks.sub(korean.id, 'Lesson')).id;
    await learnedCard(db, lessonId, 'c1');
    await lockScheduler(db, korean.id);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  test('at local midnight the window slides a day, Today returns to 0 and '
      'the streak is held from yesterday, with no write (BR-PROGRESS-018; '
      'UC-PROGRESS-001 A4)', () async {
    await answer(db, 'c1', DateTime(2026, 9, 25, 9));
    final clock = FakeDayClock(evening);
    final snapshots = <Progress>[];
    final subscription = WatchProgressUseCase(
      ProgressRepositoryImpl(db),
      clock,
    ).call().listen(snapshots.add);
    await pumpEventQueue();
    final before = await totalChanges(db);
    expect(snapshots.last.overview.today.total, 1);

    clock.startDay(DateTime(2026, 9, 26));
    await pumpEventQueue();

    final overview = snapshots.last.overview;
    expect(overview.today.total, 0);
    expect(overview.lastSevenDays.last.date, DateTime(2026, 9, 26));
    expect(
      (overview.streak.days, overview.streak.state),
      (1, StreakState.heldFromYesterday),
    );
    expect(snapshots.last.validUntil, DateTime(2026, 9, 27).toUtc());
    expect(await totalChanges(db), before);
    await subscription.cancel();
  });

  test(
    "at local midnight a deck's week slides too (UC-PROGRESS-002 A4)",
    () async {
      // Six days before the evening: the last day of its week.
      await answer(db, 'c1', DateTime(2026, 9, 19, 9));
      final clock = FakeDayClock(evening);
      final snapshots = <DeckProgress>[];
      final subscription = WatchDeckProgressUseCase(
        ProgressRepositoryImpl(db),
        clock,
      ).call(lessonId).listen(snapshots.add);
      await pumpEventQueue();
      RangeProgress total() =>
          (snapshots.last as DeckProgressLevel).level.total;
      expect(total().week.activeCards, 1);

      clock.startDay(DateTime(2026, 9, 26));
      await pumpEventQueue();

      expect(total().week.activeCards, 0);
      expect(total().month.activeCards, 1);
      await subscription.cancel();
    },
  );
}

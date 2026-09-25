import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/usecases/watch_study_home_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-002 step 5 and A2: the Study tab across a local midnight.

(int, int) overdueAndDueToday(StudyHome home) {
  final workload = home.content as RootDeckWorkload;
  return (workload.overdueCount, workload.dueTodayCount);
}

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  test("at local midnight a card due today becomes Overdue and yesterday's "
      'session is no longer offered, with no write (BR-STUDY-068, '
      'BR-STUDY-075)', () async {
    final evening = DateTime(2026, 9, 25, 21);
    final decks = DeckRepositoryImpl(db, now: () => evening);
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'today',
      deckId: lesson.id,
      back: 'today',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 25),
      box: 2,
    );
    await insertCard(db, id: 'new', deckId: lesson.id, back: 'new');
    await lockScheduler(db, root.id);
    final opened = await studyEntryRepository(
      db,
      () => evening,
    ).openLearningSession(deckId: lesson.id);
    final id = (opened as Ok<String, StudyRejection>).value;
    final clock = FakeDayClock(evening);
    final homes = <StudyHome>[];

    final subscription = WatchStudyHomeUseCase(
      StudyHomeRepositoryImpl(db),
      clock,
    ).call().listen(homes.add);
    await pumpEventQueue();
    final before = await totalChanges(db);
    expect(homes.last.resumable?.sessionId, id);
    expect(overdueAndDueToday(homes.last), (0, 1));

    clock.startDay(DateTime(2026, 9, 26));
    await pumpEventQueue();

    expect(homes.last.resumable, isNull);
    expect(overdueAndDueToday(homes.last), (1, 0));
    expect(await totalChanges(db), before);
    await subscription.cancel();
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/domain/usecases/watch_study_entry_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 1–2 and 4 through the use case the Study Entry watches.

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('a new local day makes a card due with no write (BR-STUDY-067, '
      'BR-STUDY-074)', () async {
    final decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 25),
      box: 2,
    );
    await lockScheduler(db, root.id);
    final clock = FakeDayClock(DateTime(2026, 9, 24, 22));
    final seen = <Outcome<StudyEntry, StudyRejection>>[];
    final subscription = WatchStudyEntryUseCase(
      studyEntryRepository(db, clock.now),
      clock,
    )(deckId: leaf.id).listen(seen.add);
    await pumpEventQueue();

    clock.startDay(DateTime(2026, 9, 25));
    await pumpEventQueue();
    await subscription.cancel();

    final [before, after] = [
      for (final outcome in seen)
        (outcome as Ok<StudyEntry, StudyRejection>).value.dueCardCount,
    ];
    expect((before, after), (0, 1));
  });

  test('a deck that is gone is notFound (UC-STUDY-001 E1)', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 24, 9));

    final outcome = await WatchStudyEntryUseCase(
      studyEntryRepository(db, clock.now),
      clock,
    )(deckId: 'missing').first;

    expect(
      (outcome as Rejected<StudyEntry, StudyRejection>).reason,
      StudyRejection.notFound,
    );
  });
}

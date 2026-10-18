import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';

import '../../../support/progress_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/progress_days_fixture.dart';

// DEV-208, BR-PROGRESS-016: the streak needs the run of days that follow
// each other back from its anchor (today, else yesterday), and the latest
// active day; `activeDays` reads those and nothing older, so the history is
// never folded whole. `progressOverviewOf` takes the streak and the last
// active day from this list.

void main() {
  late AppDatabase db;
  late ProgressDao dao;
  final days = noonInHanoi;

  setUp(() async {
    db = openTestDatabase();
    dao = ProgressDao(db);
    final decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, root.id);
  });
  tearDown(() => db.close());

  // September days answered, and the active days `activeDays` returns for
  // them: offsets from today.
  for (final (name, answered, expected) in const [
    (
      'the run ending today, and nothing before its gap',
      [15, 16, 17, 24, 25],
      [-1, 0],
    ),
    (
      'the run ending yesterday when today has nothing yet',
      [20, 23, 24],
      [-2, -1],
    ),
    ('a lost streak: the latest active day alone', [10, 11, 20], [-5]),
    ('nothing ever: no day', <int>[], <int>[]),
  ]) {
    test(name, () async {
      for (final day in answered) {
        await answer(db, 'c1', hanoi(9, day, 9));
      }

      expect(await dao.activeDays(days), [
        for (final offset in expected) days.today + offset,
      ]);
    });
  }

  test('a day after today, a browse row and a trashed card count for '
      'nothing (D7)', () async {
    await answer(db, 'c1', hanoi(9, 24, 9));
    await answer(db, 'c1', hanoi(9, 26, 9));
    await answer(db, 'c1', hanoi(9, 25, 9), mode: 'browse');

    expect(await dao.activeDays(days), [days.today - 1]);

    await db.customStatement(
      "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) "
      "VALUES ('b', 'card', 'c1', 0)",
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = 'c1'",
    );

    expect(await dao.activeDays(days), isEmpty);
  });
}

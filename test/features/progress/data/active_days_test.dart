import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';

import '../../../support/progress_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// DEV-208, BR-PROGRESS-016: the streak needs the run of days that follow
// each other back from its anchor (today, else yesterday), and the latest
// active day; `activeDays` reads those and nothing older, so the history is
// never folded whole. `progressOverviewOf` takes the streak and the last
// active day from this list.

void main() {
  late AppDatabase db;
  late ProgressDao dao;
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

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

  test('the run ending today, and nothing before its gap', () async {
    for (final day in [15, 16, 17, 24, 25]) {
      await answer(db, 'c1', hanoi(9, day, 9));
    }

    expect(await dao.activeDays(days), [days.today - 1, days.today]);
  });

  test('the run ending yesterday when today has nothing yet', () async {
    for (final day in [20, 23, 24]) {
      await answer(db, 'c1', hanoi(9, day, 9));
    }

    expect(await dao.activeDays(days), [days.today - 2, days.today - 1]);
  });

  test('a lost streak: the latest active day alone', () async {
    for (final day in [10, 11, 20]) {
      await answer(db, 'c1', hanoi(9, day, 9));
    }

    expect(await dao.activeDays(days), [days.today - 5]);
  });

  test('nothing ever: no day', () async {
    expect(await dao.activeDays(days), isEmpty);
  });

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

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-PROGRESS-001 and UC-PROGRESS-002 at the library level: what one
// snapshot of `/progress` says (Progress spec §5, §6).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ProgressRepositoryImpl progress;
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    progress = ProgressRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<Progress> read([ProgressDays? at]) =>
      progress.watchProgress(at ?? days).first;

  /// A root deck with one sub-deck holding the learned cards [ids].
  Future<String> tree(String root, List<String> ids) async {
    final deck = await decks.root(root);
    final lesson = await decks.sub(deck.id, '$root lesson');
    for (final id in ids) {
      await learnedCard(db, lesson.id, id);
    }
    await lockScheduler(db, deck.id);
    return deck.id;
  }

  (int, int, int, int) numbersOf(ProgressNumbers numbers) => (
    numbers.activeCards,
    numbers.activeDays,
    numbers.learningCardDays,
    numbers.reviewingCardDays,
  );

  test('six answers to one card in one evening are one card-day and one '
      'active day (BR-PROGRESS-002, BR-PROGRESS-011)', () async {
    await tree('Korean', ['c1']);
    for (final minute in [0, 10, 20, 30, 40, 50]) {
      await answer(db, 'c1', hanoi(9, 24, 20, minute));
    }

    final snapshot = await read();

    expect(numbersOf(snapshot.level.total.week), (1, 1, 0, 1));
    expect(
      [for (final day in snapshot.overview.lastSevenDays) day.total],
      [0, 0, 0, 0, 0, 1, 0],
    );
  });

  test('two decks studied on one day are one active day at the level above '
      '(BR-PROGRESS-002)', () async {
    await tree('Korean', ['k1']);
    await tree('English', ['e1']);
    await answer(db, 'k1', hanoi(9, 24, 9));
    await answer(db, 'e1', hanoi(9, 24, 21));

    final level = (await read()).level;

    expect(numbersOf(level.total.week), (2, 1, 0, 2));
    expect(
      [
        for (final deck in level.decksFor(ProgressRange.week))
          deck.progress.week.activeDays,
      ],
      [1, 1],
    );
  });

  test('a card-day with a learning answer is Learning, whatever else that '
      'day holds; scheduled and relearning are Reviewing (BR-PROGRESS-005, '
      'BR-PROGRESS-014)', () async {
    await tree('Korean', ['c1', 'c2', 'c3']);
    await answer(db, 'c1', hanoi(9, 25, 9), kind: 'learning');
    await answer(db, 'c1', hanoi(9, 25, 10));
    await answer(db, 'c2', hanoi(9, 25, 10), kind: 'relearning');
    await answer(db, 'c3', hanoi(9, 25, 11));

    final snapshot = await read();
    final today = snapshot.overview.today;

    expect((today.learning, today.reviewing, today.total), (1, 2, 3));
    expect(numbersOf(snapshot.level.total.week), (3, 1, 1, 2));
  });

  test("23:30 and 00:30 local fall on two days at the read's offset; read "
      'at another offset they fall on one (BR-PROGRESS-011)', () async {
    await tree('Korean', ['c1']);
    await answer(db, 'c1', hanoi(9, 23, 23, 30));
    await answer(db, 'c1', hanoi(9, 24, 0, 30));

    final atHanoi = (await read()).level.total.week;
    final atUtc = (await read(
      ProgressDays.of(DateTime.utc(2026, 9, 25, 5), Duration.zero),
    )).level.total.week;

    expect((atHanoi.activeDays, atHanoi.cardDays), (2, 2));
    expect((atUtc.activeDays, atUtc.cardDays), (1, 1));
  });

  test('the week is today and the six days before, the month today and the '
      '29 before, each from local midnight, both from one read '
      '(BR-PROGRESS-003, BR-PROGRESS-011)', () async {
    await tree('Korean', ['six', 'seven', 'twentyNine', 'thirty']);
    // 03:00 in Hanoi is still the day before in UTC; 23:00 is the same day.
    await answer(db, 'six', hanoi(9, 19, 3));
    await answer(db, 'seven', hanoi(9, 18, 23));
    await answer(db, 'twentyNine', hanoi(8, 27, 3));
    await answer(db, 'thirty', hanoi(8, 26, 23));

    final total = (await read()).level.total;

    expect(numbersOf(total.week), (1, 1, 0, 1));
    expect(numbersOf(total.month), (3, 3, 0, 3));
  });

  test('an answer at 00:00:00 local falls on its new day and one at '
      '23:59:59 on the day before, at Today and at the first day of the '
      'month (BR-PROGRESS-003, BR-PROGRESS-011)', () async {
    await tree('Korean', ['midnight', 'lastSecond', 'monthStart', 'before']);
    await answer(db, 'midnight', hanoi(9, 25, 0));
    // 23:59:59 on 24 September, then on 26 August, in Hanoi.
    await answer(db, 'lastSecond', DateTime.utc(2026, 9, 24, 16, 59, 59));
    await answer(db, 'monthStart', hanoi(8, 27, 0));
    await answer(db, 'before', DateTime.utc(2026, 8, 26, 16, 59, 59));

    final snapshot = await read();

    expect(snapshot.overview.today.total, 1);
    expect(snapshot.overview.lastSevenDays[5].total, 1);
    expect(snapshot.level.total.month.activeCards, 3);
  });

  test(
    "a root deck's numbers are its whole tree's (BR-PROGRESS-004)",
    () async {
      final korean = await decks.root('Korean');
      final lesson = await decks.sub(korean.id, 'Lesson');
      final unit = await decks.sub(lesson.id, 'Unit');
      await learnedCard(db, unit.id, 'deep');
      await lockScheduler(db, korean.id);
      await answer(db, 'deep', hanoi(9, 25, 9));

      final deck = (await read()).level.decksFor(ProgressRange.week).single;

      expect((deck.deckId, deck.progress.week.activeCards), (korean.id, 1));
    },
  );

  test('every root deck is listed, those with no activity last '
      '(BR-PROGRESS-006; UC-PROGRESS-002 A3)', () async {
    await decks.root('Alpha');
    await tree('Beta', ['b1']);
    await tree('Charlie', ['c1']);
    await answer(db, 'b1', hanoi(9, 25, 9));

    final rows = (await read()).level.decksFor(ProgressRange.week);

    expect([for (final deck in rows) deck.name], ['Beta', 'Alpha', 'Charlie']);
    expect(
      [for (final deck in rows) deck.progress.week.hasActivity],
      [true, false, false],
    );
  });

  test('a browse row, a card in the Trash, a deck in the Trash and an answer '
      'dated after today count nowhere (BR-PROGRESS-012; spec D7)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final trashed = await decks.sub(korean.id, 'Trashed');
    await learnedCard(db, lesson.id, 'browsed');
    await learnedCard(db, lesson.id, 'future');
    await insertCard(
      db,
      id: 'gone',
      deckId: lesson.id,
      back: 'gone',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
      box: 2,
      deleteBatchId: 'batch',
    );
    await insertCard(
      db,
      id: 'inTrashedDeck',
      deckId: trashed.id,
      back: 'kept',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
      box: 2,
    );
    await trashDeckRows(db, trashed.id);
    await lockScheduler(db, korean.id);
    await answer(db, 'browsed', hanoi(9, 25, 9), mode: 'browse');
    await answer(db, 'gone', hanoi(9, 25, 9));
    await answer(db, 'inTrashedDeck', hanoi(9, 25, 9));
    // 03:00 tomorrow in Hanoi, still today in UTC.
    await answer(db, 'future', hanoi(9, 26, 3));

    final snapshot = await read();

    expect(numbersOf(snapshot.level.total.month), (0, 0, 0, 0));
    expect(snapshot.overview.streak.state, StreakState.never);
  });

  test('never studied: every root deck with zeros, and the overview says '
      'never (UC-PROGRESS-001 A2, UC-PROGRESS-002 A3)', () async {
    await tree('Korean', ['c1']);

    final snapshot = await read();

    expect(snapshot.level.decksFor(ProgressRange.month).single.name, 'Korean');
    expect(snapshot.level.total.month.hasActivity, isFalse);
    expect(snapshot.overview.hasLifetimeActivity, isFalse);
  });

  test('a library with no deck has no row (UC-PROGRESS-002 A2)', () async {
    expect((await read()).level.hasDecks, isFalse);
  });
}

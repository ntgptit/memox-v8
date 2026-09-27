import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-PROGRESS-002 steps 5 and 6, A1 and E2: `/progress/:deckId`, a deck's
// level (Progress spec §5.2, §6.2).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ProgressRepositoryImpl progress;
  final now = DateTime(2026, 9, 25, 12);
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    progress = ProgressRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<DeckProgress> read(String deckId) =>
      progress.watchDeckProgress(deckId: deckId, days: days).first;

  Future<DeckProgressLevel> levelOf(String deckId) async =>
      (await read(deckId)) as DeckProgressLevel;

  /// The month's active cards per row, in the list's order.
  Map<String, int> monthCards(DeckProgressLevel level) => {
    for (final deck in level.level.decksFor(ProgressRange.month))
      deck.name: deck.progress.month.activeCards,
  };

  test("a deck's level lists its direct children, each with its whole "
      'subtree; its total holds every card below it (BR-PROGRESS-004; '
      'UC-PROGRESS-002 step 5)', () async {
    final korean = await decks.root('Korean');
    final grammar = await decks.sub(korean.id, 'Grammar');
    final unit = await decks.sub(grammar.id, 'Unit');
    final vocab = await decks.sub(korean.id, 'Vocab');
    await learnedCard(db, unit.id, 'g1');
    await learnedCard(db, vocab.id, 'v1');
    await learnedCard(db, vocab.id, 'v2');
    await lockScheduler(db, korean.id);
    await answer(db, 'g1', hanoi(9, 24, 9));
    await answer(db, 'v1', hanoi(9, 24, 10));
    await answer(db, 'v2', hanoi(9, 25, 9));

    final level = await levelOf(korean.id);

    expect([for (final step in level.path) step.name], ['Korean']);
    expect(monthCards(level), {'Vocab': 2, 'Grammar': 1});
    expect(
      (level.level.total.month.activeCards, level.level.total.month.activeDays),
      (3, 2),
    );
  });

  test('a deck of cards has no row, its total counts its own cards, and its '
      'path runs from the root (UC-PROGRESS-002 A1)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 25, 9));

    final level = await levelOf(lesson.id);

    expect(
      [for (final step in level.path) step.deckId],
      [korean.id, lesson.id],
    );
    expect(level.level.hasDecks, isFalse);
    expect(level.level.total.week.activeCards, 1);
  });

  test('a card moved to a sibling deck takes its history there '
      '(BR-PROGRESS-004)', () async {
    final korean = await decks.root('Korean');
    final a = await decks.sub(korean.id, 'A');
    final b = await decks.sub(korean.id, 'B');
    await learnedCard(db, a.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 10, 9));

    final moved = await CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => now),
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    ).moveCards(cardIds: {'c1'}, targetDeckId: b.id);
    expect(moved, isA<Ok<void, CardRejection>>());

    expect(monthCards(await levelOf(korean.id)), {'B': 1, 'A': 0});
  });

  test('a deck deleted, in the Trash or never there is missing, not an '
      'error (UC-PROGRESS-002 E2)', () async {
    final korean = await decks.root('Korean');
    final deleted = await decks.sub(korean.id, 'Deleted');
    final trashed = await decks.sub(korean.id, 'Trashed');
    expect(
      await decks.deleteDeck(deckId: deleted.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await trashDeckRows(db, trashed.id);

    expect(await read(deleted.id), isA<ProgressDeckMissing>());
    expect(await read(trashed.id), isA<ProgressDeckMissing>());
    expect(await read('no such deck'), isA<ProgressDeckMissing>());
  });

  test("a deck's level reads again on an answer and a renamed child, and "
      'turns missing when the deck is deleted (BR-PROGRESS-008)', () async {
    final korean = await decks.root('Korean');
    final grammar = await decks.sub(korean.id, 'Grammar');
    final unit = await decks.sub(grammar.id, 'Unit');
    await learnedCard(db, unit.id, 'c1');
    await lockScheduler(db, korean.id);
    final snapshots = <DeckProgress>[];
    final subscription = progress
        .watchDeckProgress(deckId: grammar.id, days: days)
        .listen(snapshots.add);
    await pumpEventQueue();

    await answer(db, 'c1', hanoi(9, 25, 9));
    await pumpEventQueue();
    expect(monthCards(snapshots.last as DeckProgressLevel), {'Unit': 1});

    expect(
      await decks.renameDeck(deckId: unit.id, name: 'Unit 1'),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(monthCards(snapshots.last as DeckProgressLevel), {'Unit 1': 1});

    expect(
      await decks.deleteDeck(deckId: grammar.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(snapshots.last, isA<ProgressDeckMissing>());
    await subscription.cancel();
  });

  test("a child in the Trash is neither listed nor counted at its parent's "
      'level (spec D7)', () async {
    final korean = await decks.root('Korean');
    final kept = await decks.sub(korean.id, 'Kept');
    final trashed = await decks.sub(korean.id, 'Trashed');
    await learnedCard(db, kept.id, 'k1');
    await insertCard(
      db,
      id: 't1',
      deckId: trashed.id,
      back: 't1',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
      box: 2,
    );
    await trashDeckRows(db, trashed.id);
    await lockScheduler(db, korean.id);
    await answer(db, 'k1', hanoi(9, 25, 9));
    await answer(db, 't1', hanoi(9, 25, 9));

    final level = await levelOf(korean.id);

    expect(monthCards(level), {'Kept': 1});
    expect(level.level.total.month.activeCards, 1);
  });

  test(
    'a deck moved to another root while its level is open takes its new '
    'path, and its numbers stay (BR-PROGRESS-004, BR-PROGRESS-008)',
    () async {
      final korean = await decks.root('Korean');
      final english = await decks.root('English');
      final lesson = await decks.sub(korean.id, 'Lesson');
      await learnedCard(db, lesson.id, 'c1');
      await lockScheduler(db, korean.id);
      await lockScheduler(db, english.id);
      await answer(db, 'c1', hanoi(9, 25, 9));
      final snapshots = <DeckProgress>[];
      final subscription = progress
          .watchDeckProgress(deckId: lesson.id, days: days)
          .listen(snapshots.add);
      await pumpEventQueue();

      expect(
        await decks.moveDeck(deckId: lesson.id, newParentId: english.id),
        isA<Ok<void, DeckRejection>>(),
      );
      await pumpEventQueue();

      final level = snapshots.last as DeckProgressLevel;
      expect([for (final step in level.path) step.name], ['English', 'Lesson']);
      expect(level.level.total.week.activeCards, 1);
      await subscription.cancel();
    },
  );

  test('an empty deck has no row and zero numbers, and is not missing '
      '(UC-PROGRESS-002 A1)', () async {
    final korean = await decks.root('Korean');
    final empty = await decks.sub(korean.id, 'Empty');

    final level = await levelOf(empty.id);

    expect(level.level.hasDecks, isFalse);
    expect(level.level.total.month.hasActivity, isFalse);
  });

  test("reading a deck's level writes nothing (BR-PROGRESS-007)", () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 25, 9));
    final before = await totalChanges(db);

    await read(korean.id);
    await read('no such deck');

    expect(await totalChanges(db), before);
  });
}

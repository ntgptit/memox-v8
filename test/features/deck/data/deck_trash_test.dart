import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-DECK-002 and BR-DECK-022: a deck delete moves the deck and its active
// subtree to the Trash as one batch (BR-TRASH-001, BR-TRASH-003 to
// BR-TRASH-005; trash spec §6.1).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    entries = studyEntryRepository(db, () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<String> delete(String deckId) async => ((await decks.deleteDeck(
    deckId: deckId,
  )) as Ok<String, DeckRejection>).value;

  /// Each row of [table] by id: its batch, null while it is active.
  Future<Map<String, String?>> marksOf(String table) async => {
    for (final row
        in await db
            .customSelect('SELECT id, delete_batch_id FROM $table')
            .get())
      row.read<String>('id'): row.read<String?>('delete_batch_id'),
  };

  /// Each row of [table], every column but `delete_batch_id`.
  Future<List<Map<String, Object?>>> contentOf(String table) async => [
    for (final row
        in await db.customSelect('SELECT * FROM $table ORDER BY rowid').get())
      {...row.data}..remove('delete_batch_id'),
  ];

  test('a deck goes to the Trash with every active deck and card under it, '
      'as one batch of the deck at one time, and the batch comes back '
      '(BR-TRASH-001, BR-DECK-022)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    final food = await decks.sub(words.id, 'Food');
    final grammar = await decks.sub(root.id, 'Grammar');
    await insertCard(db, id: 'f1', deckId: food.id);
    await insertCard(db, id: 'f2', deckId: food.id);
    await insertCard(db, id: 'g1', deckId: grammar.id);

    final batchId = await delete(words.id);

    expect(await marksOf('deck'), {
      root.id: null,
      words.id: batchId,
      food.id: batchId,
      grammar.id: null,
    });
    expect(await marksOf('card'), {'f1': batchId, 'f2': batchId, 'g1': null});
    final batch = await db
        .customSelect(
          'SELECT item_type, root_item_id, deleted_at FROM delete_batches'
          ' WHERE id = ?',
          variables: [Variable(batchId)],
        )
        .getSingle();
    expect(batch.read<String>('item_type'), 'deck');
    expect(batch.read<String>('root_item_id'), words.id);
    expect(batch.read<DateTime>('deleted_at'), clock);
  });

  test(
    'marking changes no content, no updated_at and no place: parents, '
    'decks, positions and schedules stay as they were (trash spec §6.4)',
    () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      await insertCard(
        db,
        id: 'f1',
        deckId: food.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 30),
      );
      await lockScheduler(db, root.id);
      final decksBefore = await contentOf('deck');
      final cardsBefore = await contentOf('card');
      final schedulesBefore = await contentOf('card_schedule');
      clock = DateTime(2026, 9, 26, 10);

      await delete(words.id);

      expect(await contentOf('deck'), decksBefore);
      expect(await contentOf('card'), cardsBefore);
      expect(await contentOf('card_schedule'), schedulesBefore);
    },
  );

  test('a tombstone inside keeps its own, older batch: the new batch takes '
      'only the rows still active (BR-TRASH-003)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    final food = await decks.sub(words.id, 'Food');
    final drinks = await decks.sub(words.id, 'Drinks');
    await insertCard(db, id: 'f1', deckId: food.id);
    await insertCard(db, id: 'd1', deckId: drinks.id);
    final older = await delete(drinks.id);
    clock = clock.add(const Duration(minutes: 5));

    final newer = await delete(words.id);

    expect(await marksOf('deck'), {
      root.id: null,
      words.id: newer,
      food.id: newer,
      drinks.id: older,
    });
    expect(await marksOf('card'), {'f1': newer, 'd1': older});
  });

  test('a sub-deck left with no active child becomes unset; a root stays a '
      'deck of decks (BR-TRASH-005)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    final food = await decks.sub(words.id, 'Food');

    await delete(food.id);
    expect(
      (await decks.findById(words.id))!.contentType,
      DeckContentType.unset,
    );

    await delete(words.id);
    expect((await decks.findById(root.id))!.contentType, DeckContentType.deck);
  });

  test('a deck that is gone or already in the Trash is notFound, and nothing '
      'is written (UC-DECK-002)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    await delete(words.id);
    final before = await totalChanges(db);

    for (final deckId in ['missing', words.id]) {
      expect(
        await decks.deleteDeck(deckId: deckId),
        isA<Rejected<String, DeckRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          DeckRejection.notFound,
        ),
      );
    }
    expect(await totalChanges(db), before);
  });

  group('the sessions a delete touches close as content_deleted '
      '(BR-TRASH-004)', () {
    Future<String> learning(String deckId) async =>
        ((await entries.openLearningSession(
          deckId: deckId,
        )) as Ok<String, StudyRejection>).value;

    Future<void> expectClosed(String sessionId) async {
      final session = await sessionOf(db, sessionId);
      expect(session.read<String>('status'), 'invalidated');
      expect(session.read<String>('end_reason'), 'content_deleted');
      expect(session.read<DateTime>('ended_at'), clock);
    }

    test('the session of the deck itself', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final id = await learning(lesson.id);
      clock = clock.add(const Duration(minutes: 1));

      await delete(lesson.id);

      await expectClosed(id);
    });

    test(
      'a session of a parent whose queue holds a card of the batch',
      () async {
        final root = await decks.root('Korean');
        final lesson = await decks.sub(root.id, 'Lesson');
        final other = await decks.sub(root.id, 'Other');
        await insertCard(db, id: 'c1', deckId: lesson.id);
        await insertCard(db, id: 'c2', deckId: other.id);
        final id = await learning(root.id);

        await delete(lesson.id);

        await expectClosed(id);
      },
    );

    test('a session whose stored guess question uses a card of the batch as '
        'an option (trash spec D7)', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(
        db,
        id: 'asked',
        deckId: lesson.id,
        back: 'library',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 20),
      );
      for (final (index, meaning) in [
        'kitchen',
        'school',
        'office',
        'garden',
      ].indexed) {
        await insertCard(
          db,
          id: 'd$index',
          deckId: other.id,
          back: meaning,
          learnedAt: DateTime(2026, 9, 1),
          dueAt: DateTime(2026, 10, 20),
        );
      }
      await lockScheduler(db, root.id);
      final opened = await entries.openReviewSession(
        deckId: lesson.id,
        mode: StudyMode.guess,
      );
      final id = (opened as Ok<String, StudyRejection>).value;
      expect(
        await optionsOf(db, id, 'asked'),
        containsAll(['d0', 'd1', 'd2', 'd3']),
      );

      await delete(other.id);

      await expectClosed(id);
    });

    test('a session opened in the tree of a deck in the batch, though its own '
        'deck has moved to another tree since (IT-CONT-006)', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.root('Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final id = await learning(lesson.id);
      expect(
        await decks.moveDeck(deckId: lesson.id, newParentId: other.id),
        isA<Ok<void, DeckRejection>>(),
      );

      await delete(root.id);

      await expectClosed(id);
    });

    test('a session that touches nothing of the batch stays open', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: other.id);
      final id = await learning(lesson.id);

      await delete(other.id);

      expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');
    });
  });
}

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-CARD-001 A2: a card delete moves each card to the Trash as a batch of
// its own (BR-TRASH-001, BR-TRASH-004, BR-TRASH-005; trash spec §6.2).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late StudyEntryRepositoryImpl entries;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => clock),
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
    entries = studyEntryRepository(db, () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<List<String>> delete(Set<String> cardIds) async =>
      ((await cards.deleteCards(
        cardIds: cardIds,
      )) as Ok<List<String>, CardRejection>).value;

  Future<String?> batchOf(String cardId) async =>
      (await db
              .customSelect(
                'SELECT delete_batch_id FROM card WHERE id = ?',
                variables: [Variable(cardId)],
              )
              .getSingle())
          .read<String?>('delete_batch_id');

  /// Each row of [table], every column but `delete_batch_id`.
  Future<List<Map<String, Object?>>> contentOf(String table) async => [
    for (final row
        in await db.customSelect('SELECT * FROM $table ORDER BY rowid').get())
      {...row.data}..remove('delete_batch_id'),
  ];

  test('deleting three cards writes three batches at one time, each card the '
      'item root of its own, in the order asked (BR-TRASH-001)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    for (final id in ['c1', 'c2', 'c3', 'kept']) {
      await insertCard(db, id: id, deckId: lesson.id);
    }

    final batchIds = await delete({'c3', 'c1', 'c2'});

    expect(batchIds.toSet(), hasLength(3));
    expect([
      for (final id in ['c3', 'c1', 'c2']) await batchOf(id),
    ], batchIds);
    expect(await batchOf('kept'), isNull);
    final batches = await db
        .customSelect(
          'SELECT item_type, root_item_id, deleted_at FROM delete_batches'
          ' ORDER BY root_item_id',
        )
        .get();
    expect(
      [
        for (final batch in batches)
          (
            batch.read<String>('item_type'),
            batch.read<String>('root_item_id'),
            batch.read<DateTime>('deleted_at'),
          ),
      ],
      [('card', 'c1', clock), ('card', 'c2', clock), ('card', 'c3', clock)],
    );
  });

  test('marking changes no content, no updated_at, no deck and no schedule '
      '(trash spec §6.4)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: lesson.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );
    await insertCard(db, id: 'c2', deckId: lesson.id);
    await lockScheduler(db, root.id);
    final cardsBefore = await contentOf('card');
    final schedulesBefore = await contentOf('card_schedule');
    clock = DateTime(2026, 9, 26, 10);

    await delete({'c1'});

    expect(await contentOf('card'), cardsBefore);
    expect(await contentOf('card_schedule'), schedulesBefore);
  });

  test('a card that is gone or already in the Trash refuses the whole set as '
      'notFound, and nothing is written; an empty set writes nothing '
      '(UC-CARD-001 A2)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    await insertCard(db, id: 'c2', deckId: lesson.id);
    await delete({'c2'});
    final before = await totalChanges(db);

    for (final cardIds in [
      {'c1', 'missing'},
      {'c1', 'c2'},
    ]) {
      expect(
        await cards.deleteCards(cardIds: cardIds),
        isA<Rejected<List<String>, CardRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          CardRejection.notFound,
        ),
      );
    }
    expect(await delete({}), isEmpty);
    expect(await totalChanges(db), before);
  });

  test(
    'a selection of 1,000 cards goes in one call: 1,000 batches at one '
    'time, and the deck left empty is unset (BR-TRASH-001, BR-TRASH-005)',
    () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final ids = {for (var i = 0; i < 1000; i++) 'c$i'};
      for (final id in ids) {
        await insertCard(db, id: id, deckId: lesson.id);
      }

      final batchIds = await delete(ids);

      expect(batchIds.toSet(), hasLength(1000));
      final batches = await db
          .customSelect(
            'SELECT COUNT(*) AS n, COUNT(DISTINCT deleted_at) AS times'
            ' FROM delete_batches',
          )
          .getSingle();
      expect((batches.read<int>('n'), batches.read<int>('times')), (1000, 1));
      final deck = await db
          .customSelect(
            'SELECT content_type FROM deck WHERE id = ?',
            variables: [Variable(lesson.id)],
          )
          .getSingle();
      expect(deck.read<String>('content_type'), 'unset');
    },
  );

  group('the sessions a delete touches close as content_deleted '
      '(BR-TRASH-004)', () {
    Future<void> expectClosed(String sessionId) async {
      final session = await sessionOf(db, sessionId);
      expect(session.read<String>('status'), 'invalidated');
      expect(session.read<String>('end_reason'), 'content_deleted');
      expect(session.read<DateTime>('ended_at'), clock);
    }

    test('a session whose queue holds the card', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: lesson.id);
      final opened = await entries.openLearningSession(deckId: lesson.id);
      final id = (opened as Ok<String, StudyRejection>).value;
      clock = clock.add(const Duration(minutes: 1));

      await delete({'c2'});

      await expectClosed(id);
    });

    test('a session whose stored guess question uses the card as an option '
        '(trash spec D7)', () async {
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
      expect(await optionsOf(db, id, 'asked'), contains('d0'));

      await delete({'d0'});

      await expectClosed(id);
    });

    test('a session that touches none of the cards stays open', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: other.id);
      final opened = await entries.openLearningSession(deckId: lesson.id);
      final id = (opened as Ok<String, StudyRejection>).value;

      await delete({'c2'});

      expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');
    });
  });
}

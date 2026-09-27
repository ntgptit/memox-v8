import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TRASH-001 steps 5-7 and BR-TRASH-006 to BR-TRASH-008: a card comes back
// from the Trash into a deck of its root, and an Undo takes it back where it
// was (trash spec §7.2, §7.3).

Matcher _refused(CardRejection reason) => isA<Rejected<void, CardRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
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
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<List<String>> delete(Set<String> cardIds) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await cards.deleteCards(
      cardIds: cardIds,
    )) as Ok<List<String>, CardRejection>).value;
  }

  Future<String> deleteDeck(String deckId) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: deckId,
    )) as Ok<String, DeckRejection>).value;
  }

  /// Where [cardId] sits: its deck, its batch and its updated_at.
  Future<(String, String?, DateTime)> placeOf(String cardId) async {
    final row = await db
        .customSelect(
          'SELECT deck_id, delete_batch_id, updated_at FROM card WHERE id = ?',
          variables: [Variable(cardId)],
        )
        .getSingle();
    return (
      row.read<String>('deck_id'),
      row.read<String?>('delete_batch_id'),
      row.read<DateTime>('updated_at'),
    );
  }

  Future<DeckContentType> contentTypeOf(String deckId) async =>
      (await decks.findById(deckId))!.contentType;

  group('restoreCards (BR-TRASH-006, BR-TRASH-007)', () {
    test(
      'the cards go into the chosen deck of their root, stamped as a move '
      'stamps them, and their batches go; an unset target takes cards',
      () async {
        final root = await decks.root('Korean');
        final lesson = await decks.sub(root.id, 'Lesson');
        final empty = await decks.sub(root.id, 'Empty');
        await insertCard(db, id: 'c1', deckId: lesson.id);
        await insertCard(db, id: 'c2', deckId: lesson.id);
        final batchIds = await delete({'c1', 'c2'});
        clock = clock.add(const Duration(minutes: 1));

        expect(
          await cards.restoreCards(
            batchIds: batchIds.toSet(),
            deckId: empty.id,
          ),
          isA<Ok<void, CardRejection>>(),
        );

        expect(await placeOf('c1'), (empty.id, null, clock));
        expect(await placeOf('c2'), (empty.id, null, clock));
        expect(await contentTypeOf(empty.id), DeckContentType.card);
        expect(await contentTypeOf(lesson.id), DeckContentType.unset);
        expect(
          (await db
                  .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
                  .getSingle())
              .read<int>('n'),
          0,
        );
      },
    );

    test('a card whose deck is in the Trash too comes back into another deck '
        'of the same root', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final [batchId] = await delete({'c1'});
      await deleteDeck(lesson.id);

      expect(
        await cards.restoreCards(batchIds: {batchId}, deckId: other.id),
        isA<Ok<void, CardRejection>>(),
      );
      expect((await placeOf('c1')).$1, other.id);
    });

    test('a card in the Trash through a reset that changed the scheduler '
        "comes back at its root's generation, under the new scheduler "
        '(trash spec D11)', () async {
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
      final [batchId] = await delete({'c1'});
      await ScheduleRepositoryImpl(
        db,
        now: () => clock,
      ).resetLearning(rootDeckId: root.id, schedulerType: SchedulerType.sm2);

      expect(
        await cards.restoreCards(batchIds: {batchId}, deckId: lesson.id),
        isA<Ok<void, CardRejection>>(),
      );

      final schedule = await db
          .customSelect(
            'SELECT scheduler_type, generation, learned_at FROM card_schedule'
            " WHERE card_id = 'c1'",
          )
          .getSingle();
      expect(
        (
          schedule.read<String>('scheduler_type'),
          schedule.read<int>('generation'),
          schedule.read<DateTime?>('learned_at'),
        ),
        ('sm2', 2, null),
      );
    });

    test(
      'each refusal writes nothing, and one refusal refuses them all',
      () async {
        final root = await decks.root('Korean');
        final lesson = await decks.sub(root.id, 'Lesson');
        final parent = await decks.sub(root.id, 'Parent');
        await decks.sub(parent.id, 'Child');
        final trashed = await decks.sub(root.id, 'Trashed');
        final english = await decks.root('English');
        final words = await decks.sub(english.id, 'Words');
        await insertCard(db, id: 'c1', deckId: lesson.id);
        await insertCard(db, id: 'c2', deckId: lesson.id);
        final [batchId] = await delete({'c1'});
        final deckBatch = await deleteDeck(trashed.id);
        final before = await totalChanges(db);

        final cases = <(Set<String>, String, CardRejection)>[
          ({'missing'}, lesson.id, CardRejection.notFound),
          ({deckBatch}, lesson.id, CardRejection.notFound),
          ({batchId}, trashed.id, CardRejection.targetInTrash),
          ({batchId}, 'missing', CardRejection.targetNotFound),
          ({batchId}, root.id, CardRejection.targetIsRoot),
          ({batchId}, parent.id, CardRejection.targetHoldsDecks),
          ({batchId}, words.id, CardRejection.crossRootMove),
          ({batchId, 'missing'}, lesson.id, CardRejection.notFound),
        ];
        for (final (batchIds, deckId, reason) in cases) {
          expect(
            await cards.restoreCards(batchIds: batchIds, deckId: deckId),
            _refused(reason),
            reason: '$reason',
          );
        }
        expect(await totalChanges(db), before);
      },
    );
  });

  group('undoCardDeletion (BR-TRASH-008)', () {
    test('a card goes back into its deck with its updated_at kept, and the '
        'deck takes cards again', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final updatedAt = (await placeOf('c1')).$3;
      final [batchId] = await delete({'c1'});
      expect(await contentTypeOf(lesson.id), DeckContentType.unset);

      expect(
        await cards.undoCardDeletion(batchId: batchId),
        isA<Ok<void, CardRejection>>(),
      );

      expect(await placeOf('c1'), (lesson.id, null, updatedAt));
      expect(await contentTypeOf(lesson.id), DeckContentType.card);
    });

    test('refused, typed, when its deck is in the Trash or holds decks now, '
        'and nothing is written', () async {
      final root = await decks.root('Korean');
      final gone = await decks.sub(root.id, 'Gone');
      final grown = await decks.sub(root.id, 'Grown');
      await insertCard(db, id: 'c1', deckId: gone.id);
      await insertCard(db, id: 'c2', deckId: grown.id);
      final [first] = await delete({'c1'});
      await deleteDeck(gone.id);
      final [second] = await delete({'c2'});
      await decks.sub(grown.id, 'Child');
      final before = await totalChanges(db);

      expect(
        await cards.undoCardDeletion(batchId: first),
        _refused(CardRejection.targetInTrash),
      );
      expect(
        await cards.undoCardDeletion(batchId: second),
        _refused(CardRejection.targetHoldsDecks),
      );
      expect(
        await cards.undoCardDeletion(batchId: 'missing'),
        _refused(CardRejection.notFound),
      );
      expect(await totalChanges(db), before);
    });

    test('a second Undo, or one after the card came back from the Trash, is '
        'notFound and writes nothing', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: lesson.id);
      final [undone] = await delete({'c1'});
      final [restored] = await delete({'c2'});
      await cards.undoCardDeletion(batchId: undone);
      await cards.restoreCards(batchIds: {restored}, deckId: lesson.id);
      final before = await totalChanges(db);

      for (final batchId in [undone, restored]) {
        expect(
          await cards.undoCardDeletion(batchId: batchId),
          _refused(CardRejection.notFound),
        );
      }
      expect(await totalChanges(db), before);
    });
  });
}

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRASH-001 steps 5-7 and BR-TRASH-006 to BR-TRASH-008: a deck comes back
// from the Trash under the rules of a move, and an Undo takes it back where
// it was (trash spec §7.1, §7.3).

Matcher _refused(DeckRejection reason) => isA<Rejected<void, DeckRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<String> delete(String deckId) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: deckId,
    )) as Ok<String, DeckRejection>).value;
  }

  /// Where [deckId] sits: parent, root, depth, position and batch.
  Future<(String?, String, int, int, String?)> placeOf(String deckId) async {
    final row = await db
        .customSelect(
          'SELECT parent_id, root_id, depth, sibling_position, delete_batch_id'
          ' FROM deck WHERE id = ?',
          variables: [Variable(deckId)],
        )
        .getSingle();
    return (
      row.read<String?>('parent_id'),
      row.read<String>('root_id'),
      row.read<int>('depth'),
      row.read<int>('sibling_position'),
      row.read<String?>('delete_batch_id'),
    );
  }

  Future<int> batchCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
              .getSingle())
          .read<int>('n');

  group('restoreDecks (BR-TRASH-006, BR-TRASH-007)', () {
    test('a sub-deck goes under the chosen deck, last among its children, '
        'with its subtree and cards, and its batch goes', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final grammar = await decks.sub(root.id, 'Grammar');
      await decks.sub(grammar.id, 'Verbs');
      await insertCard(db, id: 'f1', deckId: food.id);
      final batch = await delete(words.id);

      expect(
        await decks.restoreDecks(batchIds: {batch}, parentId: grammar.id),
        isA<Ok<void, DeckRejection>>(),
      );

      expect(await placeOf(words.id), (grammar.id, root.id, 3, 1, null));
      expect(await placeOf(food.id), (words.id, root.id, 4, 0, null));
      expect(await decks.findById(food.id), isNotNull);
      expect(
        (await db
                .customSelect(
                  "SELECT delete_batch_id FROM card WHERE id = 'f1'",
                )
                .getSingle())
            .read<String?>('delete_batch_id'),
        isNull,
      );
      expect(await batchCount(), 0);
    });

    test('an unset target becomes a deck of decks (BR-DECK-015)', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final empty = await decks.sub(root.id, 'Empty');
      final batch = await delete(words.id);

      await decks.restoreDecks(batchIds: {batch}, parentId: empty.id);

      expect((await decks.findById(empty.id))!.contentType.name, 'deck');
    });

    test('a tombstone inside stays in the Trash with its own batch and moves '
        'with its subtree, across roots of one scheduler and generation '
        '(BR-TRASH-003, UC-TRASH-001 A5)', () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final english = await decks.root('English');
      final older = await delete(food.id);
      final newer = await delete(words.id);

      await decks.restoreDecks(batchIds: {newer}, parentId: english.id);

      expect(await placeOf(words.id), (english.id, english.id, 2, 0, null));
      expect(await placeOf(food.id), (words.id, english.id, 3, 0, older));
    });

    test('a sub-deck whose root went to the Trash after it comes back under '
        'a deck of another root of its scheduler and generation', () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final english = await decks.root('English');
      final target = await decks.sub(english.id, 'Target');
      final foodBatch = await delete(food.id);
      final koreanBatch = await delete(korean.id);

      expect(
        await decks.restoreDecks(batchIds: {foodBatch}, parentId: target.id),
        isA<Ok<void, DeckRejection>>(),
      );

      expect(await placeOf(food.id), (target.id, english.id, 3, 0, null));
      expect((await placeOf(words.id)).$5, koreanBatch);
    });

    test('a batch and an older one inside it come back together, the outer '
        'first, each under the chosen deck at its own depth', () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final fruit = await decks.sub(food.id, 'Fruit');
      final english = await decks.root('English');
      final target = await decks.sub(english.id, 'Target');
      final inner = await delete(food.id);
      final outer = await delete(words.id);

      expect(
        await decks.restoreDecks(batchIds: {outer, inner}, parentId: target.id),
        isA<Ok<void, DeckRejection>>(),
      );

      expect(await placeOf(words.id), (target.id, english.id, 3, 0, null));
      expect(await placeOf(food.id), (target.id, english.id, 3, 1, null));
      expect(await placeOf(fruit.id), (food.id, english.id, 4, 0, null));
    });

    test(
      'a root deck goes back to the top level, last among the roots',
      () async {
        final korean = await decks.root('Korean');
        final batch = await delete(korean.id);
        final english = await decks.root('English');

        await decks.restoreDecks(batchIds: {batch}, parentId: null);

        expect(await placeOf(korean.id), (null, korean.id, 1, 2, null));
        expect((await placeOf(english.id)).$4, 1);
      },
    );

    test('several batches come back in the order given', () async {
      final root = await decks.root('Korean');
      final a = await decks.sub(root.id, 'A');
      final b = await decks.sub(root.id, 'B');
      final target = await decks.sub(root.id, 'Target');
      final first = await delete(b.id);
      final second = await delete(a.id);

      await decks.restoreDecks(batchIds: {first, second}, parentId: target.id);

      expect((await placeOf(b.id)).$4, 0);
      expect((await placeOf(a.id)).$4, 1);
    });

    test(
      'each refusal writes nothing, and one refusal refuses them all',
      () async {
        final korean = await decks.root('Korean');
        final words = await decks.sub(korean.id, 'Words');
        final cards = await decks.sub(korean.id, 'Cards');
        await insertCard(db, id: 'c1', deckId: cards.id);
        final gone = await decks.sub(korean.id, 'Gone');
        final sm2 = await decks.root('Other', SchedulerType.sm2);
        var parent = korean.id;
        for (var level = 2; level <= DeckEntity.maxDepth; level++) {
          parent = (await decks.sub(parent, 'L$level')).id;
        }
        final deepest = parent;
        final wordsBatch = await delete(words.id);
        final goneBatch = await delete(gone.id);
        final rootBatch = await delete((await decks.root('Root')).id);
        await insertCard(db, id: 'c2', deckId: cards.id);
        await trashCardRow(db, 'c2', batchId: 'card-batch');
        final before = await totalChanges(db);

        final cases = <(Set<String>, String?, DeckRejection)>[
          ({'missing'}, korean.id, DeckRejection.notFound),
          ({'card-batch'}, korean.id, DeckRejection.notFound),
          ({wordsBatch}, null, DeckRejection.subDeckNeedsParent),
          ({rootBatch}, korean.id, DeckRejection.rootRestoresToTopLevel),
          ({wordsBatch}, gone.id, DeckRejection.targetInTrash),
          ({wordsBatch}, 'missing', DeckRejection.targetNotFound),
          ({wordsBatch}, cards.id, DeckRejection.notADeckContainer),
          ({wordsBatch}, deepest, DeckRejection.depthExceeded),
          ({wordsBatch}, sm2.id, DeckRejection.subtreeSchedulerMismatch),
          (
            {wordsBatch, goneBatch, 'missing'},
            korean.id,
            DeckRejection.notFound,
          ),
        ];
        for (final (batchIds, parentId, reason) in cases) {
          expect(
            await decks.restoreDecks(batchIds: batchIds, parentId: parentId),
            _refused(reason),
            reason: '$reason',
          );
        }
        expect(await totalChanges(db), before);
      },
    );
  });

  group('undoDeckDeletion (BR-TRASH-008)', () {
    test('a sub-deck goes back under its parent at its old position, though '
        'a sibling came after it', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      await decks.sub(words.id, 'Food');
      await decks.sub(root.id, 'Grammar');
      final batch = await delete(words.id);
      await decks.sub(root.id, 'Later');

      expect(
        await decks.undoDeckDeletion(batchId: batch),
        isA<Ok<void, DeckRejection>>(),
      );

      expect(await placeOf(words.id), (root.id, root.id, 2, 0, null));
      expect(await batchCount(), 0);
    });

    test(
      'a root deck goes back to the top level at its old position',
      () async {
        final korean = await decks.root('Korean');
        final batch = await delete(korean.id);
        await decks.root('English');

        await decks.undoDeckDeletion(batchId: batch);

        expect(await placeOf(korean.id), (null, korean.id, 1, 0, null));
      },
    );

    test('refused, typed, when the old place no longer takes it, and nothing '
        'is written', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final lesson = await decks.sub(root.id, 'Lesson');
      final verbs = await decks.sub(lesson.id, 'Verbs');
      final foodBatch = await delete(food.id);
      await delete(words.id);
      final verbsBatch = await delete(verbs.id);
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final before = await totalChanges(db);

      expect(
        await decks.undoDeckDeletion(batchId: foodBatch),
        _refused(DeckRejection.targetInTrash),
      );
      expect(
        await decks.undoDeckDeletion(batchId: verbsBatch),
        _refused(DeckRejection.notADeckContainer),
      );
      expect(
        await decks.undoDeckDeletion(batchId: 'missing'),
        _refused(DeckRejection.notFound),
      );
      expect(await totalChanges(db), before);
    });

    test('a second Undo, or one after the deck came back from the Trash, is '
        'notFound and writes nothing', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final grammar = await decks.sub(root.id, 'Grammar');
      final undone = await delete(words.id);
      final restored = await delete(grammar.id);
      await decks.undoDeckDeletion(batchId: undone);
      await decks.restoreDecks(batchIds: {restored}, parentId: root.id);
      final before = await totalChanges(db);

      for (final batchId in [undone, restored]) {
        expect(
          await decks.undoDeckDeletion(batchId: batchId),
          _refused(DeckRejection.notFound),
        );
      }
      expect(await totalChanges(db), before);
    });
  });
}

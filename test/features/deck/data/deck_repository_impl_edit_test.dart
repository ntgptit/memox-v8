import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// The edits stage 2 adds to the deck repository: rename, reorder, a move to
// the parent a deck already has, the deletion summary, and decks in the Trash.

DeckRejection _reason(Outcome<Object?, DeckRejection> result) =>
    (result as Rejected<Object?, DeckRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  setUp(() {
    db = openTestDatabase();
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  Future<List<(String, int)>> siblings(String? parentId) async {
    final rows = await db
        .customSelect(
          'SELECT name, sibling_position FROM deck WHERE parent_id IS ? '
          'ORDER BY sibling_position, id',
          variables: [Variable<String>(parentId)],
        )
        .get();
    return [
      for (final row in rows)
        (row.read<String>('name'), row.read<int>('sibling_position')),
    ];
  }

  Future<void> insertCard(String id, String deckId, {String? batch}) async {
    if (batch != null) {
      await insertDeleteBatch(db, batch, itemType: 'card', rootItemId: id);
    }
    await db.customStatement(
      "UPDATE deck SET content_type = 'card' WHERE id = ?",
      [deckId],
    );
    await db.customStatement(
      'INSERT INTO card (id, deck_id, front, back, delete_batch_id, '
      "created_at, updated_at) VALUES (?, ?, 'f', 'b', ?, 0, 0)",
      [id, deckId, batch],
    );
  }

  group('renameDeck', () {
    test(
      'stores the trimmed name and stamps updated_at (BR-DECK-020)',
      () async {
        final r = await repo.root('r');
        final later = DateTime(2026, 9, 24);

        final result = await repo.renameDeck(
          deckId: r.id,
          name: '  Korean  ',
          now: later,
        );

        expect(result, isA<Ok<void, DeckRejection>>());
        final renamed = (await repo.findById(r.id))!;
        expect((renamed.name, renamed.updatedAt), ('Korean', later));
      },
    );

    test(
      'refuses a blank or too long name and a missing deck, writing nothing',
      () async {
        final r = await repo.root('r');
        final before = await totalChanges(db);

        expect(
          _reason(await repo.renameDeck(deckId: r.id, name: ' ')),
          DeckRejection.blankName,
        );
        expect(
          _reason(await repo.renameDeck(deckId: r.id, name: 'a' * 201)),
          DeckRejection.nameTooLong,
        );
        expect(
          _reason(await repo.renameDeck(deckId: 'missing', name: 'x')),
          DeckRejection.notFound,
        );
        expect(await totalChanges(db), before);
      },
    );
  });

  group('reorderDeck (BR-SRS-007)', () {
    test(
      'puts the deck before or after its anchor and numbers the group from 0',
      () async {
        final r = await repo.root('r');
        final a = await repo.sub(r.id, 'a');
        await repo.sub(r.id, 'b');
        final c = await repo.sub(r.id, 'c');

        await repo.reorderDeck(
          deckId: c.id,
          anchorId: a.id,
          placement: DeckPlacement.before,
        );
        expect(await siblings(r.id), [('c', 0), ('a', 1), ('b', 2)]);

        await repo.reorderDeck(
          deckId: c.id,
          anchorId: a.id,
          placement: DeckPlacement.after,
        );
        expect(await siblings(r.id), [('a', 0), ('c', 1), ('b', 2)]);
      },
    );

    test(
      'only the decks whose position changed get a new updated_at',
      () async {
        final r = await repo.root('r');
        final a = await repo.sub(r.id, 'a');
        final b = await repo.sub(r.id, 'b');
        final c = await repo.sub(r.id, 'c');
        final later = DateTime(2026, 9, 24);

        await repo.reorderDeck(
          deckId: b.id,
          anchorId: c.id,
          placement: DeckPlacement.after,
          now: later,
        );

        expect(await siblings(r.id), [('a', 0), ('c', 1), ('b', 2)]);
        expect((await repo.findById(a.id))!.updatedAt, DateTime(2026, 9, 23));
        expect((await repo.findById(b.id))!.updatedAt, later);
        expect((await repo.findById(c.id))!.updatedAt, later);
      },
    );

    test('root decks reorder among the roots', () async {
      final x = await repo.root('x');
      final y = await repo.root('y');

      await repo.reorderDeck(
        deckId: y.id,
        anchorId: x.id,
        placement: DeckPlacement.before,
      );

      expect(await siblings(null), [('y', 0), ('x', 1)]);
    });

    test(
      'decks that no longer share a parent are refused, writing nothing',
      () async {
        final r = await repo.root('r');
        final a = await repo.sub(r.id, 'a');
        final b = await repo.sub(r.id, 'b');
        final inner = await repo.sub(a.id, 'inner');
        final before = await totalChanges(db);

        final result = await repo.reorderDeck(
          deckId: inner.id,
          anchorId: b.id,
          placement: DeckPlacement.before,
        );

        expect(_reason(result), DeckRejection.notSiblings);
        expect(await totalChanges(db), before);
      },
    );

    test('a missing deck or anchor answers notFound', () async {
      final r = await repo.root('r');
      final a = await repo.sub(r.id, 'a');

      final result = await repo.reorderDeck(
        deckId: a.id,
        anchorId: 'missing',
        placement: DeckPlacement.before,
      );

      expect(_reason(result), DeckRejection.notFound);
      expect(await siblings(r.id), [('a', 0)]);
    });
  });

  test('moving a deck to the parent it has is refused as sameParent, writing nothing', () async {
    final r = await repo.root('r');
    final a = await repo.sub(r.id, 'a');
    final before = await totalChanges(db);

    final result = await repo.moveDeck(deckId: a.id, newParentId: r.id);

    expect(_reason(result), DeckRejection.sameParent);
    expect(await totalChanges(db), before);
  });

  group('deletionSummary (BR-DECK-023)', () {
    test('counts every deck below and every card in the subtree', () async {
      final r = await repo.root('r');
      final branch = await repo.sub(r.id, 'branch');
      final leaf = await repo.sub(branch.id, 'leaf');
      await repo.sub(branch.id, 'empty');
      await insertCard('c1', leaf.id);

      final ofRoot = await repo.deletionSummary(r.id);
      final ofLeaf = await repo.deletionSummary(leaf.id);

      final rootSummary =
          (ofRoot as Ok<DeckDeletionSummary, DeckRejection>).value;
      final leafSummary =
          (ofLeaf as Ok<DeckDeletionSummary, DeckRejection>).value;
      expect((rootSummary.subDeckCount, rootSummary.cardCount), (3, 1));
      expect((leafSummary.subDeckCount, leafSummary.cardCount), (0, 1));
    });

    test('a missing deck answers notFound', () async {
      expect(
        _reason(await repo.deletionSummary('missing')),
        DeckRejection.notFound,
      );
    });
  });

  test(
    'a deck in the Trash is out of reach and not counted (spec §8)',
    () async {
      final r = await repo.root('r');
      final kept = await repo.sub(r.id, 'kept');
      final trashed = await repo.sub(r.id, 'trashed');
      await insertCard('c1', kept.id);
      await insertCard('gone', kept.id, batch: 'batch');
      await trashDeckRows(db, trashed.id);

      expect(await repo.findById(trashed.id), isNull);
      final reorder = await repo.reorderDeck(
        deckId: kept.id,
        anchorId: trashed.id,
        placement: DeckPlacement.after,
      );
      expect(_reason(reorder), DeckRejection.notFound);
      final summary = await repo.deletionSummary(r.id);
      final counts = (summary as Ok<DeckDeletionSummary, DeckRejection>).value;
      expect((counts.subDeckCount, counts.cardCount), (1, 1));
    },
  );
}

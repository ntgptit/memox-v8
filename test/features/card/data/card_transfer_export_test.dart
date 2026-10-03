import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import 'card_transfer_fixture.dart';

// The read of an export: the card feature's half of Card Transfer
// (UC-TRANSFER-002).

void main() {
  useCardTransferFixture();

  group('exportSnapshot (BR-TRANSFER-007, BR-TRANSFER-010, BR-TRANSFER-011)', () {
    // `c` is inserted before `b` on the same day, so insertion order alone
    // would put `c` first (BR-TRANSFER-010).
    setUp(() async {
      await insertCard(
        db,
        id: 'c',
        deckId: leaf.id,
        front: 'tie',
        back: '3',
        createdAt: DateTime(2026, 9, 2),
      );
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: 'first',
        back: '1',
        hint: 'h',
        createdAt: DateTime(2026, 9, 1),
      );
      await insertCard(
        db,
        id: 'b',
        deckId: leaf.id,
        front: 'second',
        back: '2',
        createdAt: DateTime(2026, 9, 2),
      );
      await insertCard(
        db,
        id: 'z',
        deckId: leaf.id,
        front: 'gone',
        back: '4',
        deleteBatchId: 'batch',
      );
      await TagRepositoryImpl(db, now: transferNow).replaceForCard(
        cardId: 'a',
        names: ['zeta', 'Alpha'],
        now: transferNow(),
      );
    });

    test(
      'the live cards by created_at then id, their six fields and sorted tags',
      () async {
        final snapshot = okOf(await cards.exportSnapshot(deckId: leaf.id));

        expect(snapshot.deckName, 'l');
        expect(snapshot.rows.map((row) => row.front), [
          'first',
          'second',
          'tie',
        ]);
        final first = snapshot.rows.first;
        expect((first.back, first.hint, first.example), ('1', 'h', null));
        expect(first.tagNames, ['Alpha', 'zeta']);
      },
    );

    test(
      'a selection keeps that order whatever order it was touched in',
      () async {
        final snapshot = okOf(
          await cards.exportSnapshot(deckId: leaf.id, cardIds: {'c', 'a'}),
        );

        expect(snapshot.rows.map((row) => row.front), ['first', 'tie']);
      },
    );

    test('an id that is gone, in the Trash or in another deck is skipped; the '
        'rest are read (SP2a 2.19, BR-TRANSFER-007)', () async {
      final other = await decks.sub(root.id, 'o');
      await insertCard(db, id: 'x', deckId: other.id);

      for (final id in ['missing', 'z', 'x']) {
        final snapshot = okOf(
          await cards.exportSnapshot(deckId: leaf.id, cardIds: {'a', id}),
        );
        expect(snapshot.rows.map((row) => row.front), ['first'], reason: id);
        expect(snapshot.skipped, {id}, reason: id);
      }
      expect(
        reasonOf(await cards.exportSnapshot(deckId: 'missing')),
        CardRejection.notFound,
      );
    });

    test(
      'an empty deck is an empty snapshot, and reading writes nothing',
      () async {
        final empty = await decks.sub(root.id, 'e');
        final before = await totalChanges(db);

        expect(
          okOf(await cards.exportSnapshot(deckId: empty.id)).rows,
          isEmpty,
        );
        okOf(await cards.exportSnapshot(deckId: leaf.id));
        expect(await totalChanges(db), before);
      },
    );
  });
}

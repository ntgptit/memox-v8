import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';
import 'card_batch_writes_fixture.dart';

// The flag batch (BR-CARD-011) and the writes a Trash puts out of reach
// (spec §8), each all or nothing in one transaction.

DateTime _t0() => DateTime(2026, 9, 23);
final _later = DateTime(2026, 9, 24);

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

void main() {
  useBatchWritesFixture();

  group('setFlagged (BR-CARD-011)', () {
    test(
      'sets the value given on every card; a card already at it is not written',
      () async {
        final flagged = await cards.card(
          nouns.id,
          const CardDraft(front: 'f', back: 'b', isFlagged: true),
        );
        final plain = await cards.card(nouns.id);

        await cards.setFlagged(
          cardIds: {flagged.id, plain.id},
          isFlagged: true,
          now: _later,
        );

        expect(
          (
            (await cardRow(flagged.id))['is_flagged'],
            (await cardRow(flagged.id))['updated_at'],
          ),
          (1, seconds(_t0())),
        );
        expect(
          (
            (await cardRow(plain.id))['is_flagged'],
            (await cardRow(plain.id))['updated_at'],
          ),
          (1, seconds(_later)),
        );

        await cards.setFlagged(
          cardIds: {flagged.id, plain.id},
          isFlagged: false,
        );

        expect(
          [
            (await cardRow(flagged.id))['is_flagged'],
            (await cardRow(plain.id))['is_flagged'],
          ],
          [0, 0],
        );
      },
    );

    test(
      'a card already gone is skipped; the rest are flagged (SP2a 2.19)',
      () async {
        final a = await cards.card(nouns.id);

        final result = await cards.setFlagged(
          cardIds: {a.id, 'missing'},
          isFlagged: true,
        );

        final outcome = (result as Ok<BulkOutcome, CardRejection>).value;
        expect(outcome.done, {a.id});
        expect(outcome.skipped, {'missing'});
        expect((await cardRow(a.id))['is_flagged'], 1);
        final before = await totalChanges(db);
        expect(
          _reason(
            await cards.setFlagged(cardIds: {'missing'}, isFlagged: true),
          ),
          CardRejection.notFound,
        );
        expect(await totalChanges(db), before);
      },
    );

    test('when every selected id is gone nothing is written and the outcome '
        'says all of them were skipped (SP2a 2.19, Review Focus)', () async {
      final a = await cards.card(nouns.id);
      await trashCardRow(db, a.id);
      final before = await totalChanges(db);

      final results = [
        await cards.deleteCards(cardIds: {a.id, 'missing'}),
        await cards.moveCards(
          cardIds: {a.id, 'missing'},
          targetDeckId: verbs.id,
        ),
        await cards.setFlagged(cardIds: {a.id, 'missing'}, isFlagged: true),
      ];

      for (final result in results) {
        expect(_reason(result), CardRejection.notFound);
      }
      expect(await totalChanges(db), before);
    });
  });

  test(
    'an empty batch writes nothing, and an unset target stays unset',
    () async {
      final empty = await decks.sub(root.id, 'Empty');
      final before = await totalChanges(db);

      expect(
        await cards.deleteCards(cardIds: {}),
        isA<Ok<BulkOutcome, CardRejection>>(),
      );
      expect(
        await cards.moveCards(cardIds: {}, targetDeckId: empty.id),
        isA<Ok<void, CardRejection>>(),
      );
      expect(
        await cards.setFlagged(cardIds: {}, isFlagged: true),
        isA<Ok<void, CardRejection>>(),
      );
      expect(await totalChanges(db), before);
      expect(await contentTypeOf(empty.id), DeckContentType.unset);
    },
  );

  test('a card or a deck in the Trash is out of reach of every card write (spec §8)', () async {
    final card = await cards.card(nouns.id);
    final trashedCard = await cards.card(nouns.id);
    final trashedDeck = await decks.sub(root.id, 'Trashed');
    await trashCardRow(db, trashedCard.id);
    await trashDeckRows(db, trashedDeck.id);
    final before = await totalChanges(db);
    const draft = CardDraft(front: 'f', back: 'b');

    expect(
      _reason(await cards.editCard(cardId: trashedCard.id, draft: draft)),
      CardRejection.notFound,
    );
    expect(
      _reason(await cards.deleteCards(cardIds: {trashedCard.id})),
      CardRejection.notFound,
    );
    expect(
      _reason(
        await cards.moveCards(
          cardIds: {trashedCard.id},
          targetDeckId: verbs.id,
        ),
      ),
      CardRejection.notFound,
    );
    expect(
      _reason(
        await cards.setFlagged(cardIds: {trashedCard.id}, isFlagged: true),
      ),
      CardRejection.notFound,
    );
    expect(
      _reason(
        await cards.moveCards(cardIds: {card.id}, targetDeckId: trashedDeck.id),
      ),
      CardRejection.targetNotFound,
    );
    expect(
      _reason(await cards.createCard(deckId: trashedDeck.id, draft: draft)),
      CardRejection.notFound,
    );
    expect(await totalChanges(db), before);
  });

  group('a deck in the Trash that still holds a live card (spec §8)', () {
    // Invariant 33 forbids this state and no write path creates it. It is
    // built by hand to show the card writes do not lean on it: the deck row
    // is out of reach, whatever the card's own row says.
    late DeckEntity trashed;
    late String cardId;
    setUp(() async {
      trashed = await decks.sub(root.id, 'Trashed');
      cardId = (await cards.card(trashed.id)).id;
      await insertDeleteBatch(
        db,
        'b',
        itemType: 'deck',
        rootItemId: trashed.id,
      );
      await db.customStatement(
        "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
        [trashed.id],
      );
    });

    Future<Map<String, Object?>> deckRow(String deckId) async =>
        (await db
                .customSelect(
                  'SELECT * FROM deck WHERE id = ?',
                  variables: [Variable(deckId)],
                )
                .getSingle())
            .data;

    test('deleting its last card leaves the deck row as it was', () async {
      final before = await deckRow(trashed.id);

      expect(
        await cards.deleteCards(cardIds: {cardId}),
        isA<Ok<BulkOutcome, CardRejection>>(),
      );
      expect(await deckRow(trashed.id), before);
    });

    test('moving its card out is refused: the source deck is out of reach, '
        'so the cross-root rule cannot be checked', () async {
      final before = await totalChanges(db);

      expect(
        await cards.moveCards(
          cardIds: {cardId},
          targetDeckId: verbs.id,
          now: _later,
        ),
        isA<Rejected<void, CardRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          CardRejection.notFound,
        ),
      );
      expect(await totalChanges(db), before);
    });
  });
}

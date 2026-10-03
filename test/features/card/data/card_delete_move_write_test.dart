import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';
import 'card_batch_writes_fixture.dart';

// The delete and move batches (BR-CARD-010, BR-CARD-011), each all or
// nothing in one transaction.

DateTime _t0() => DateTime(2026, 9, 23);
final _later = DateTime(2026, 9, 24);

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

void main() {
  useBatchWritesFixture();

  group('deleteCards (BR-CARD-011)', () {
    test('moves the cards to the Trash with their schedule rows and tag links; an emptied deck is unset', () async {
      final a = await cards.card(
        nouns.id,
        const CardDraft(front: 'a', back: 'a', tagNames: ['t']),
      );
      final b = await cards.card(verbs.id);
      await cards.card(verbs.id);

      final result = await cards.deleteCards(cardIds: {a.id, b.id});

      expect(result, isA<Ok<BulkOutcome, CardRejection>>());
      expect(
        (
          await count('card'),
          await count('card_schedule'),
          await count('card_tags'),
        ),
        (3, 3, 1),
      );
      expect(await contentTypeOf(nouns.id), DeckContentType.unset);
      expect(await contentTypeOf(verbs.id), DeckContentType.card);
    });

    test('a card already gone or in the Trash is skipped; the rest go to the '
        'Trash a batch each (SP2a 2.19)', () async {
      final a = await cards.card(nouns.id);
      final b = await cards.card(nouns.id);
      final trashed = await cards.card(nouns.id);
      await trashCardRow(db, trashed.id);

      final result = await cards.deleteCards(
        cardIds: {a.id, 'missing', b.id, trashed.id},
      );

      final outcome = (result as Ok<BulkOutcome, CardRejection>).value;
      expect(outcome.done, {a.id, b.id});
      expect(outcome.skipped, {'missing', trashed.id});
      expect(outcome.batchIds, hasLength(2));
      expect(await count('delete_batches'), 3, reason: 'two new, one fixture');
    });

    test(
      'when no card is left the batch is notFound, writing nothing',
      () async {
        final before = await totalChanges(db);

        expect(
          _reason(await cards.deleteCards(cardIds: {'missing', 'gone'})),
          CardRejection.notFound,
        );
        expect(await totalChanges(db), before);
      },
    );
  });

  group('moveCards (BR-CARD-010)', () {
    test(
      'writes only deck_id and updated_at, and both content types follow',
      () async {
        final card = await cards.card(
          nouns.id,
          const CardDraft(
            front: 'f',
            back: 'b',
            isFlagged: true,
            tagNames: ['t'],
          ),
        );
        await learn(card.id);
        final empty = await decks.sub(root.id, 'Empty');

        final result = await cards.moveCards(
          cardIds: {card.id},
          targetDeckId: empty.id,
          now: _later,
        );

        expect(result, isA<Ok<void, CardRejection>>());
        final row = await cardRow(card.id);
        expect((row['deck_id'], row['is_flagged']), (empty.id, 1));
        expect(
          (row['created_at'], row['updated_at']),
          (seconds(_t0()), seconds(_later)),
        );
        expect(await tagNamesOf(card.id), ['t']);
        final schedule = await db
            .customSelect(
              'SELECT learned_at, current_box FROM card_schedule WHERE card_id = ?',
              variables: [Variable(card.id)],
            )
            .getSingle();
        expect(schedule.data, {'learned_at': 1, 'current_box': 3});
        expect(await contentTypeOf(nouns.id), DeckContentType.unset);
        expect(await contentTypeOf(empty.id), DeckContentType.card);
      },
    );

    test('refuses a batch the rules refuse, writing nothing', () async {
      final a = await cards.card(nouns.id);
      final b = await cards.card(verbs.id);
      final branch = await decks.sub(root.id, 'Branch');
      await decks.sub(branch.id, 'Child');
      final twin = await decks.root('Twin');
      final twinLeaf = await decks.sub(twin.id, 'Twin leaf');
      final before = await totalChanges(db);

      Future<CardRejection> refusal(Set<String> ids, String targetId) async =>
          _reason(await cards.moveCards(cardIds: ids, targetDeckId: targetId));

      expect(await refusal({a.id}, 'missing'), CardRejection.targetNotFound);
      expect(await refusal({a.id}, root.id), CardRejection.targetIsRoot);
      expect(await refusal({a.id}, branch.id), CardRejection.targetHoldsDecks);
      expect(await refusal({a.id, b.id}, verbs.id), CardRejection.sameDeck);
      expect(
        await refusal({a.id}, twinLeaf.id),
        CardRejection.crossRootMove,
        reason: 'refused even though both roots run eight_box at generation 1',
      );
      expect(await totalChanges(db), before);
    });

    test(
      'a card already gone is skipped; the others move (SP2a 2.19)',
      () async {
        final a = await cards.card(nouns.id);

        final result = await cards.moveCards(
          cardIds: {a.id, 'missing'},
          targetDeckId: verbs.id,
          now: _later,
        );

        final outcome = (result as Ok<BulkOutcome, CardRejection>).value;
        expect(outcome.done, {a.id});
        expect(outcome.skipped, {'missing'});
        expect((await cardRow(a.id))['deck_id'], verbs.id);
        final before = await totalChanges(db);
        expect(
          _reason(
            await cards.moveCards(cardIds: {'missing'}, targetDeckId: verbs.id),
          ),
          CardRejection.notFound,
        );
        expect(await totalChanges(db), before);
      },
    );
  });
}

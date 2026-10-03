import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import 'card_transfer_fixture.dart';

// The card feature's half of Card Transfer: the duplicate key, the batch
// write of an import and the read of an export (UC-TRANSFER-001,
// UC-TRANSFER-002).

/// Fails the second schedule row, after one card is already written.
final class _SecondScheduleFails implements ScheduleRepository {
  _SecondScheduleFails(this._inner);

  final ScheduleRepository _inner;
  var _calls = 0;

  @override
  Future<void> initializeCard({required String cardId}) async {
    _calls++;
    if (_calls == 2) throw StateError('schedule row not written');
    await _inner.initializeCard(cardId: cardId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  useCardTransferFixture();

  group('foldedPairs (BR-TRANSFER-003)', () {
    test('the folded faces of the live cards of the deck only', () async {
      final other = await decks.sub(root.id, 'o');
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: ' Menu',
        back: 'Thực đơn',
      );
      await insertCard(
        db,
        id: 'c',
        deckId: other.id,
        front: 'bill',
        back: 'hóa đơn',
      );
      await insertCard(
        db,
        id: 'b',
        deckId: leaf.id,
        front: 'gone',
        back: 'x',
        deleteBatchId: 'batch',
      );

      expect(await cards.foldedPairs(leaf.id), {
        (front: 'menu', back: 'thực đơn'),
      });
    });
  });

  group('importCards (BR-TRANSFER-001…BR-TRANSFER-005)', () {
    test('the ids of the cards written come back, and not those a duplicate '
        'dropped (SP2a 2.25)', () async {
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: 'menu',
        back: 'thực đơn',
      );

      final result = okOf(
        await cards.importCards(
          deckId: leaf.id,
          drafts: const [
            CardDraft(front: 'menu', back: 'thực đơn'),
            CardDraft(front: 'bill', back: 'hóa đơn'),
            CardDraft(front: 'tip', back: 'tiền boa'),
          ],
          includeDuplicates: false,
        ),
      );

      expect(result.writtenIds, hasLength(2));
      final rows = await db
          .customSelect("SELECT id FROM card WHERE front IN ('bill', 'tip')")
          .get();
      expect(result.writtenIds.toSet(), {
        for (final row in rows) row.read<String>('id'),
      });
    });

    test('every draft becomes a new card with one schedule row and its tags; unset becomes card', () async {
      final result = okOf(
        await cards.importCards(
          deckId: leaf.id,
          drafts: const [
            CardDraft(
              front: 'menu',
              back: 'thực đơn',
              tagNames: ['food', 'noun'],
            ),
            CardDraft(
              front: 'bill',
              back: 'hóa đơn',
              example: 'The bill, please.',
            ),
          ],
          includeDuplicates: false,
        ),
      );

      expect((result.written, result.skippedIndexes.length), (2, 0));
      expect(await countRows(db, 'card'), 2);
      expect(await countRows(db, 'card_schedule'), 2);
      expect(await countRows(db, 'card_tags'), 2);
      expect(await countRows(db, 'review_log'), 0);
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.card,
      );
    });

    test('a draft written in the other Unicode form is a duplicate (BE-C5, '
        'BR-TRANSFER-003)', () async {
      await CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: transferNow),
        TagRepositoryImpl(db, now: transferNow),
        now: transferNow,
      ).card(leaf.id, const CardDraft(front: 'c\u00F4ng', back: 'work'));

      final result = okOf(
        await cards.importCards(
          deckId: leaf.id,
          drafts: const [CardDraft(front: 'co\u0302ng', back: 'work')],
          includeDuplicates: false,
        ),
      );

      expect((result.written, result.skippedIndexes.length), (0, 1));
    });

    test('duplicates of the deck as it is now, and within the batch, are skipped by default', () async {
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: 'menu',
        back: 'thực đơn',
      );

      final result = okOf(
        await cards.importCards(
          deckId: leaf.id,
          drafts: const [
            CardDraft(front: 'MENU ', back: 'Thực đơn'),
            CardDraft(front: 'bill', back: 'hóa đơn'),
            CardDraft(front: 'Bill', back: 'Hóa đơn'),
          ],
          includeDuplicates: false,
        ),
      );

      expect((result.written, result.skippedIndexes.length), (1, 2));
      // The drafts the commit dropped, by their place in the batch
      // (critique 2026-10-02, F4).
      expect(result.skippedIndexes, [0, 2]);
      expect(await countRows(db, 'card'), 2);
    });

    test(
      'Include duplicates writes them as new cards, never merged (A4)',
      () async {
        await insertCard(
          db,
          id: 'a',
          deckId: leaf.id,
          front: 'menu',
          back: 'thực đơn',
        );

        final result = okOf(
          await cards.importCards(
            deckId: leaf.id,
            drafts: const [CardDraft(front: 'menu', back: 'thực đơn')],
            includeDuplicates: true,
          ),
        );

        expect(result.written, 1);
        expect(await countRows(db, 'card'), 2);
      },
    );

    test(
      'a batch that writes nothing changes nothing, content_type included',
      () async {
        final before = await totalChanges(db);

        final result = okOf(
          await cards.importCards(
            deckId: leaf.id,
            drafts: const [],
            includeDuplicates: false,
          ),
        );

        expect(result.written, 0);
        expect(await totalChanges(db), before);
        expect(
          (await decks.findById(leaf.id))!.contentType,
          DeckContentType.unset,
        );
      },
    );

    test('a root, a deck holding sub-decks and a missing deck are refused; nothing is written (E4)', () async {
      await decks.sub(leaf.id, 'child');
      const drafts = [CardDraft(front: 'a', back: 'b')];

      expect(
        reasonOf(
          await cards.importCards(
            deckId: root.id,
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notACardContainer,
      );
      expect(
        reasonOf(
          await cards.importCards(
            deckId: leaf.id,
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notACardContainer,
      );
      expect(
        reasonOf(
          await cards.importCards(
            deckId: 'missing',
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notFound,
      );
      expect(await countRows(db, 'card'), 0);
    });

    test('one draft the card rules refuse refuses the batch', () async {
      final result = await cards.importCards(
        deckId: leaf.id,
        drafts: [
          const CardDraft(front: 'a', back: 'b'),
          CardDraft(front: 'x' * 61, back: 'y'),
        ],
        includeDuplicates: false,
      );

      expect(reasonOf(result), CardRejection.frontTooLong);
      expect(await countRows(db, 'card'), 0);
    });

    test(
      'a write that fails half way rolls the whole batch back (E5)',
      () async {
        final failing = CardTransferRepositoryImpl(
          db,
          CardRepositoryImpl(
            db,
            _SecondScheduleFails(ScheduleRepositoryImpl(db, now: transferNow)),
            TagRepositoryImpl(db, now: transferNow),
            now: transferNow,
          ),
        );

        await expectLater(
          failing.importCards(
            deckId: leaf.id,
            drafts: const [
              CardDraft(front: 'a', back: 'b'),
              CardDraft(front: 'c', back: 'd'),
            ],
            includeDuplicates: false,
          ),
          throwsA(isA<Failure>()),
        );
        expect(await countRows(db, 'card'), 0);
        expect(await countRows(db, 'card_schedule'), 0);
        expect(
          (await decks.findById(leaf.id))!.contentType,
          DeckContentType.unset,
        );
      },
    );

    test('1,500 drafts in one batch', () async {
      final result = okOf(
        await cards.importCards(
          deckId: leaf.id,
          drafts: [
            for (var i = 0; i < 1500; i++)
              CardDraft(
                front: 'term $i',
                back: 'meaning $i',
                tagNames: const ['bulk'],
              ),
          ],
          includeDuplicates: false,
        ),
      );

      expect(result.written, 1500);
      expect(await countRows(db, 'card_schedule'), 1500);
      expect(await countRows(db, 'tags'), 1);
    });
  });
}

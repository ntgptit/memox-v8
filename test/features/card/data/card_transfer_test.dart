import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The card feature's half of Card Transfer: the duplicate key, the batch
// write of an import and the read of an export (UC-TRANSFER-001,
// UC-TRANSFER-002).

DateTime _now() => DateTime(2026, 9, 26);

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

T _ok<T>(Outcome<T, CardRejection> result) =>
    (result as Ok<T, CardRejection>).value;

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

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
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardTransferRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardTransferRepositoryImpl(
      db,
      CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: _now),
        TagRepositoryImpl(db, now: _now),
        now: _now,
      ),
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  });
  tearDown(() => db.close());

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
    test('every draft becomes a new card with one schedule row and its tags; unset becomes card', () async {
      final result = _ok(
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

      expect((result.written, result.skippedDuplicates), (2, 0));
      expect(await _count(db, 'card'), 2);
      expect(await _count(db, 'card_schedule'), 2);
      expect(await _count(db, 'card_tags'), 2);
      expect(await _count(db, 'review_log'), 0);
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.card,
      );
    });

    test('duplicates of the deck as it is now, and within the batch, are skipped by default', () async {
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: 'menu',
        back: 'thực đơn',
      );

      final result = _ok(
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

      expect((result.written, result.skippedDuplicates), (1, 2));
      expect(await _count(db, 'card'), 2);
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

        final result = _ok(
          await cards.importCards(
            deckId: leaf.id,
            drafts: const [CardDraft(front: 'menu', back: 'thực đơn')],
            includeDuplicates: true,
          ),
        );

        expect(result.written, 1);
        expect(await _count(db, 'card'), 2);
      },
    );

    test(
      'a batch that writes nothing changes nothing, content_type included',
      () async {
        final before = await totalChanges(db);

        final result = _ok(
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
        _reason(
          await cards.importCards(
            deckId: root.id,
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notACardContainer,
      );
      expect(
        _reason(
          await cards.importCards(
            deckId: leaf.id,
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notACardContainer,
      );
      expect(
        _reason(
          await cards.importCards(
            deckId: 'missing',
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notFound,
      );
      expect(await _count(db, 'card'), 0);
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

      expect(_reason(result), CardRejection.frontTooLong);
      expect(await _count(db, 'card'), 0);
    });

    test(
      'a write that fails half way rolls the whole batch back (E5)',
      () async {
        final failing = CardTransferRepositoryImpl(
          db,
          CardRepositoryImpl(
            db,
            _SecondScheduleFails(ScheduleRepositoryImpl(db, now: _now)),
            TagRepositoryImpl(db, now: _now),
            now: _now,
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
        expect(await _count(db, 'card'), 0);
        expect(await _count(db, 'card_schedule'), 0);
        expect(
          (await decks.findById(leaf.id))!.contentType,
          DeckContentType.unset,
        );
      },
    );

    test('1,500 drafts in one batch', () async {
      final result = _ok(
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
      expect(await _count(db, 'card_schedule'), 1500);
      expect(await _count(db, 'tags'), 1);
    });
  });

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
      await TagRepositoryImpl(
        db,
        now: _now,
      ).replaceForCard(cardId: 'a', names: ['zeta', 'Alpha'], now: _now());
    });

    test(
      'the live cards by created_at then id, their six fields and sorted tags',
      () async {
        final snapshot = _ok(await cards.exportSnapshot(deckId: leaf.id));

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
        final snapshot = _ok(
          await cards.exportSnapshot(deckId: leaf.id, cardIds: {'c', 'a'}),
        );

        expect(snapshot.rows.map((row) => row.front), ['first', 'tie']);
      },
    );

    test('an id that is gone, in the Trash or in another deck fails the whole request (E6)', () async {
      final other = await decks.sub(root.id, 'o');
      await insertCard(db, id: 'x', deckId: other.id);

      for (final ids in [
        {'a', 'missing'},
        {'a', 'z'},
        {'a', 'x'},
      ]) {
        expect(
          _reason(await cards.exportSnapshot(deckId: leaf.id, cardIds: ids)),
          CardRejection.notFound,
        );
      }
      expect(
        _reason(await cards.exportSnapshot(deckId: 'missing')),
        CardRejection.notFound,
      );
    });

    test(
      'an empty deck is an empty snapshot, and reading writes nothing',
      () async {
        final empty = await decks.sub(root.id, 'e');
        final before = await totalChanges(db);

        expect(_ok(await cards.exportSnapshot(deckId: empty.id)).rows, isEmpty);
        _ok(await cards.exportSnapshot(deckId: leaf.id));
        expect(await totalChanges(db), before);
      },
    );
  });
}

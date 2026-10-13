import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
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
  late CardRepositoryImpl list;
  late CardTransferRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    list = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      DeckTreeDataSource(db),
      now: _now,
    );
    cards = CardTransferRepositoryImpl(db, list, decks);
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

      expect((result.written, result.skippedIndexes.length), (2, 0));
      expect(await _count(db, 'card'), 2);
      expect(await _count(db, 'card_schedule'), 2);
      expect(await _count(db, 'card_tags'), 2);
      expect(await _count(db, 'review_log'), 0);
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.card,
      );
    });

    test('cards of one import keep the source order in the list and in an export (DEV-216)', () async {
      // One import writes every card with the same created_at, so the
      // source order can only survive through the ids (ADR-007).
      final fronts = List.generate(12, (i) => 'row ${i + 1}');
      _ok(
        await cards.importCards(
          deckId: leaf.id,
          drafts: [for (final f in fronts) CardDraft(front: f, back: 'b')],
          includeDuplicates: false,
        ),
      );

      final snapshot = _ok(await cards.exportSnapshot(deckId: leaf.id));
      final view = await list
          .watchCardList(
            deckId: leaf.id,
            query: const CardListQuery(),
            windowSize: 50,
            now: _now(),
          )
          .first;

      expect([for (final r in snapshot.rows) r.front], fronts);
      expect([
        for (final item in view.items) item.front,
      ], fronts.reversed.toList());
    });

    test('a draft written in the other Unicode form is a duplicate (BE-C5, '
        'BR-TRANSFER-003)', () async {
      await CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: _now),
        TagRepositoryImpl(db, now: _now),
        DeckTreeDataSource(db),
        now: _now,
      ).card(leaf.id, const CardDraft(front: 'c\u00F4ng', back: 'work'));

      final result = _ok(
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

      expect((result.written, result.skippedIndexes.length), (1, 2));
      // The drafts the commit dropped, by their place in the batch
      // (critique 2026-10-02, F4).
      expect(result.skippedIndexes, [0, 2]);
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
            DeckTreeDataSource(db),
            now: _now,
          ),
          decks,
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
}

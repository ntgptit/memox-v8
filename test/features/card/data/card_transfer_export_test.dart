import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The card feature's read of an export (UC-TRANSFER-002), split from
// card_transfer_test.dart.

DateTime _now() => DateTime(2026, 9, 26);

T _ok<T>(Outcome<T, CardRejection> result) =>
    (result as Ok<T, CardRejection>).value;

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

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

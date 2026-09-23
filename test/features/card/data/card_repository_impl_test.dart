import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

import '../../../support/test_database.dart';

DateTime _now() => DateTime(2026, 9, 23);

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

/// Fails the one call `createCard` makes, to prove that the card and its
/// schedule row are written in one transaction (BR-CARD-004).
final class _FailingScheduleRepository implements ScheduleRepository {
  @override
  Future<void> initializeCard({required String cardId}) async =>
      throw StateError('schedule row not written');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      now: _now,
    );
  });
  tearDown(() => db.close());

  test(
    'creating a card sets content_type card on the (unset) parent deck',
    () async {
      final root = ((await decks.createRootDeck(
        name: 'r',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final leaf = ((await decks.createSubDeck(
        parentId: root.id,
        name: 'l',
      )) as Ok<DeckEntity, DeckRejection>).value;

      final result = await cards.createCard(
        deckId: leaf.id,
        front: 'front',
        back: 'back',
      );
      expect(result, isA<Ok<CardEntity, CardRejection>>());
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.card,
      );
    },
  );

  test('creating a card creates its schedule row from the root scheduler and generation (BR-CARD-004)', () async {
    final root = ((await decks.createRootDeck(
      name: 'r',
      schedulerType: SchedulerType.sm2,
    )) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(
      parentId: root.id,
      name: 'l',
    )) as Ok<DeckEntity, DeckRejection>).value;

    final card = ((await cards.createCard(
      deckId: leaf.id,
      front: 'f',
      back: 'b',
    )) as Ok<CardEntity, CardRejection>).value;

    final row = await db
        .customSelect(
          'SELECT scheduler_type, generation, ease_factor, current_box, learned_at, due_at '
          'FROM card_schedule WHERE card_id = ?',
          variables: [Variable(card.id)],
        )
        .getSingle();
    expect(row.read<String>('scheduler_type'), 'sm2');
    expect(row.read<int>('generation'), 1);
    expect(row.read<double>('ease_factor'), 2.5);
    expect(row.data['current_box'], isNull);
    expect(row.data['learned_at'], isNull);
    expect(row.data['due_at'], isNull);
  });

  test(
    'when the schedule row cannot be written, the card is not created either',
    () async {
      final root = ((await decks.createRootDeck(
        name: 'r',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final leaf = ((await decks.createSubDeck(
        parentId: root.id,
        name: 'l',
      )) as Ok<DeckEntity, DeckRejection>).value;
      final failing = CardRepositoryImpl(
        db,
        _FailingScheduleRepository(),
        now: _now,
      );

      await expectLater(
        failing.createCard(deckId: leaf.id, front: 'f', back: 'b'),
        throwsA(anything),
      );

      expect(await _count(db, 'card'), 0);
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.unset,
      );
    },
  );

  test('a card cannot be created directly on a root deck', () async {
    final root = ((await decks.createRootDeck(
      name: 'r',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value;
    final result = await cards.createCard(
      deckId: root.id,
      front: 'f',
      back: 'b',
    );
    expect(
      (result as Rejected<CardEntity, CardRejection>).reason,
      CardRejection.notACardContainer,
    );
    expect(await _count(db, 'card'), 0);
    expect(await _count(db, 'card_schedule'), 0);
  });

  test(
    'a card cannot be created in a deck that already holds sub-decks',
    () async {
      final root = ((await decks.createRootDeck(
        name: 'r',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final branch = ((await decks.createSubDeck(
        parentId: root.id,
        name: 'b',
      )) as Ok<DeckEntity, DeckRejection>).value;
      await decks.createSubDeck(parentId: branch.id, name: 'child');

      final result = await cards.createCard(
        deckId: branch.id,
        front: 'f',
        back: 'b',
      );
      expect(
        (result as Rejected<CardEntity, CardRejection>).reason,
        CardRejection.notACardContainer,
      );
    },
  );

  test('blank front or back is rejected', () async {
    final root = ((await decks.createRootDeck(
      name: 'r',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(
      parentId: root.id,
      name: 'l',
    )) as Ok<DeckEntity, DeckRejection>).value;

    expect(
      (await cards.createCard(
        deckId: leaf.id,
        front: '   ',
        back: 'b',
      ) as Rejected<CardEntity, CardRejection>).reason,
      CardRejection.blankContent,
    );
    expect(
      (await cards.createCard(
        deckId: leaf.id,
        front: 'f',
        back: '',
      ) as Rejected<CardEntity, CardRejection>).reason,
      CardRejection.blankContent,
    );
  });

  test(
    'optional example/hint/pronunciation trim to NULL, not empty string',
    () async {
      final root = ((await decks.createRootDeck(
        name: 'r',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final leaf = ((await decks.createSubDeck(
        parentId: root.id,
        name: 'l',
      )) as Ok<DeckEntity, DeckRejection>).value;

      final result = await cards.createCard(
        deckId: leaf.id,
        front: 'f',
        back: 'b',
        hint: '   ',
      );
      expect((result as Ok<CardEntity, CardRejection>).value.hint, isNull);
    },
  );

  test(
    'front_folded/back_folded are Unicode-lowercase, not SQL lower()',
    () async {
      final root = ((await decks.createRootDeck(
        name: 'r',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final leaf = ((await decks.createSubDeck(
        parentId: root.id,
        name: 'l',
      )) as Ok<DeckEntity, DeckRejection>).value;

      final result = await cards.createCard(
        deckId: leaf.id,
        front: 'CÔNG NGHỆ',
        back: 'technology',
      );
      final card = (result as Ok<CardEntity, CardRejection>).value;
      final row = await db
          .customSelect(
            'SELECT front_folded FROM card WHERE id = ?',
            variables: [Variable(card.id)],
          )
          .getSingle();
      expect(row.read<String>('front_folded'), 'công nghệ');
    },
  );

  test(
    'deleting the last card in a deck resets its content_type to unset',
    () async {
      final root = ((await decks.createRootDeck(
        name: 'r',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final leaf = ((await decks.createSubDeck(
        parentId: root.id,
        name: 'l',
      )) as Ok<DeckEntity, DeckRejection>).value;
      final card = ((await cards.createCard(
        deckId: leaf.id,
        front: 'f',
        back: 'b',
      )) as Ok<CardEntity, CardRejection>).value;

      await cards.deleteCard(cardId: card.id);

      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.unset,
      );
    },
  );

  test('deleting a missing card answers notFound', () async {
    final result = await cards.deleteCard(cardId: 'missing');
    expect(
      (result as Rejected<void, CardRejection>).reason,
      CardRejection.notFound,
    );
  });
}

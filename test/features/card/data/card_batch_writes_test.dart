import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The card writes stage 2 adds: edit, and the batches of BR-CARD-011, each
// all or nothing in one transaction.

DateTime _t0() => DateTime(2026, 9, 23);
final _later = DateTime(2026, 9, 24);

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity nouns;
  late DeckEntity verbs;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _t0);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _t0),
      TagRepositoryImpl(db, now: _t0),
      now: _t0,
    );
    root = await decks.root('Korean');
    nouns = await decks.sub(root.id, 'Nouns');
    verbs = await decks.sub(root.id, 'Verbs');
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');

  Future<DeckContentType> contentTypeOf(String deckId) async =>
      (await decks.findById(deckId))!.contentType;

  Future<Map<String, Object?>> cardRow(String cardId) async =>
      (await db
              .customSelect(
                'SELECT * FROM card WHERE id = ?',
                variables: [Variable(cardId)],
              )
              .getSingle())
          .data;

  Future<List<String>> tagNamesOf(String cardId) async => [
    for (final row
        in await db
            .customSelect(
              'SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id '
              'WHERE ct.card_id = ? ORDER BY t.name_folded',
              variables: [Variable(cardId)],
            )
            .get())
      row.read<String>('name'),
  ];

  Future<void> learn(String cardId) => db.customStatement(
    'UPDATE card_schedule SET learned_at = 1, due_at = 2, current_box = 3 '
    'WHERE card_id = ?',
    [cardId],
  );

  /// A card's stored seconds, as Drift writes a DateTime.
  int seconds(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

  group('editCard (BR-CARD-005)', () {
    test('replaces the content, the flag and the tags; keeps the schedule and the log', () async {
      final card = await cards.card(
        nouns.id,
        const CardDraft(front: 'f', back: 'b', tagNames: ['old']),
      );
      await learn(card.id);
      await db.customStatement(
        'INSERT INTO review_log (id, card_id, session_id, scheduler_type, '
        'generation, kind, mode, "action", answered_at) VALUES '
        "('log', ?, 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
        [card.id],
      );

      final result = await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(
          front: ' CÔNG ',
          back: 'work',
          hint: 'h',
          isFlagged: true,
          tagNames: ['Verb'],
        ),
        now: _later,
      );

      expect(result, isA<Ok<void, CardRejection>>());
      final row = await cardRow(card.id);
      expect(
        (
          row['front'],
          row['front_folded'],
          row['back'],
          row['hint'],
          row['is_flagged'],
        ),
        ('CÔNG', 'công', 'work', 'h', 1),
      );
      expect(
        (row['created_at'], row['updated_at']),
        (seconds(_t0()), seconds(_later)),
      );
      expect(await tagNamesOf(card.id), ['Verb']);
      final schedule = await db
          .customSelect(
            'SELECT learned_at, current_box FROM card_schedule WHERE card_id = ?',
            variables: [Variable(card.id)],
          )
          .getSingle();
      expect(schedule.data, {'learned_at': 1, 'current_box': 3});
      expect(await count('review_log'), 1);
    });

    test(
      'refuses a draft the rules refuse and a missing card, writing nothing',
      () async {
        final card = await cards.card(nouns.id);
        final before = await totalChanges(db);

        expect(
          _reason(
            await cards.editCard(
              cardId: card.id,
              draft: CardDraft(front: 'x' * 61, back: 'b'),
            ),
          ),
          CardRejection.frontTooLong,
        );
        expect(
          _reason(
            await cards.editCard(
              cardId: 'missing',
              draft: const CardDraft(front: 'f', back: 'b'),
            ),
          ),
          CardRejection.notFound,
        );
        expect(await totalChanges(db), before);
      },
    );
  });

  group('deleteCards (BR-CARD-011)', () {
    test('deletes the batch with its schedule rows and tag links; an emptied deck is unset', () async {
      final a = await cards.card(
        nouns.id,
        const CardDraft(front: 'a', back: 'a', tagNames: ['t']),
      );
      final b = await cards.card(verbs.id);
      await cards.card(verbs.id);

      final result = await cards.deleteCards(cardIds: {a.id, b.id});

      expect(result, isA<Ok<void, CardRejection>>());
      expect(
        (
          await count('card'),
          await count('card_schedule'),
          await count('card_tags'),
        ),
        (1, 1, 0),
      );
      expect(await contentTypeOf(nouns.id), DeckContentType.unset);
      expect(await contentTypeOf(verbs.id), DeckContentType.card);
    });

    test('one missing card refuses the whole batch', () async {
      final a = await cards.card(nouns.id);
      final before = await totalChanges(db);

      expect(
        _reason(await cards.deleteCards(cardIds: {a.id, 'missing'})),
        CardRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
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
      expect(
        await refusal({a.id, 'missing'}, verbs.id),
        CardRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
  });

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

    test('one missing card refuses the whole batch', () async {
      final a = await cards.card(nouns.id);
      final before = await totalChanges(db);

      expect(
        _reason(
          await cards.setFlagged(cardIds: {a.id, 'missing'}, isFlagged: true),
        ),
        CardRejection.notFound,
      );
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
        isA<Ok<void, CardRejection>>(),
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
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
      [trashedCard.id],
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [trashedDeck.id],
    );
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
        isA<Ok<void, CardRejection>>(),
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

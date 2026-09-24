import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

DateTime _now() => DateTime(2026, 9, 23);

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

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
  late DeckEntity root;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  });
  tearDown(() => db.close());

  test(
    'creating a card sets content_type card on the (unset) parent deck',
    () async {
      final result = await cards.createCard(
        deckId: leaf.id,
        draft: const CardDraft(front: 'front', back: 'back'),
      );

      expect(result, isA<Ok<CardEntity, CardRejection>>());
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.card,
      );
    },
  );

  test('creating a card creates its schedule row from the root scheduler and generation (BR-CARD-004)', () async {
    final sm2 = await decks.root('s', SchedulerType.sm2);
    final sm2Leaf = await decks.sub(sm2.id, 'l');

    final card = await cards.card(sm2Leaf.id);

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
      final failing = CardRepositoryImpl(
        db,
        _FailingScheduleRepository(),
        TagRepositoryImpl(db, now: _now),
        now: _now,
      );

      await expectLater(
        failing.createCard(
          deckId: leaf.id,
          draft: const CardDraft(front: 'f', back: 'b', tagNames: ['t']),
        ),
        throwsA(anything),
      );

      expect(await _count(db, 'card'), 0);
      expect(await _count(db, 'tags'), 0);
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.unset,
      );
    },
  );

  test('a card cannot be created directly on a root deck', () async {
    final result = await cards.createCard(
      deckId: root.id,
      draft: const CardDraft(front: 'f', back: 'b'),
    );

    expect(_reason(result), CardRejection.notACardContainer);
    expect(await _count(db, 'card'), 0);
    expect(await _count(db, 'card_schedule'), 0);
  });

  test(
    'a card cannot be created in a deck that already holds sub-decks',
    () async {
      final branch = await decks.sub(root.id, 'b');
      await decks.sub(branch.id, 'child');

      final result = await cards.createCard(
        deckId: branch.id,
        draft: const CardDraft(front: 'f', back: 'b'),
      );

      expect(_reason(result), CardRejection.notACardContainer);
    },
  );

  test('a draft the card rules refuse writes nothing (BR-CARD-001..003, BR-TAG-002)', () async {
    final before = await totalChanges(db);

    Future<CardRejection> refusal(CardDraft draft) async =>
        _reason(await cards.createCard(deckId: leaf.id, draft: draft));

    expect(
      await refusal(const CardDraft(front: '   ', back: 'b')),
      CardRejection.blankContent,
    );
    expect(
      await refusal(const CardDraft(front: 'f', back: '')),
      CardRejection.blankContent,
    );
    expect(
      await refusal(CardDraft(front: 'x' * 61, back: 'b')),
      CardRejection.frontTooLong,
    );
    expect(
      await refusal(
        CardDraft(
          front: 'f',
          back: 'b',
          tagNames: [for (var i = 0; i < 11; i++) 'tag $i'],
        ),
      ),
      CardRejection.tooManyTags,
    );
    expect(await totalChanges(db), before);
  });

  test('the flag and the tags of the draft are stored with the card', () async {
    final card = await cards.card(
      leaf.id,
      const CardDraft(
        front: 'f',
        back: 'b',
        isFlagged: true,
        tagNames: ['Verb', ' verb ', 'Food'],
      ),
    );

    final tags = await db
        .customSelect(
          'SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id '
          'WHERE ct.card_id = ? ORDER BY t.name_folded',
          variables: [Variable(card.id)],
        )
        .get();
    expect(card.isFlagged, isTrue);
    expect(
      [for (final row in tags) row.read<String>('name')],
      ['Food', 'Verb'],
    );
  });

  test(
    'optional example/hint/pronunciation trim to NULL, not empty string',
    () async {
      final card = await cards.card(
        leaf.id,
        const CardDraft(front: 'f', back: 'b', hint: '   '),
      );

      expect(card.hint, isNull);
    },
  );

  test(
    'front_folded/back_folded are Unicode-lowercase, not SQL lower()',
    () async {
      final card = await cards.card(
        leaf.id,
        const CardDraft(front: 'CÔNG NGHỆ', back: 'technology'),
      );

      final row = await db
          .customSelect(
            'SELECT front_folded FROM card WHERE id = ?',
            variables: [Variable(card.id)],
          )
          .getSingle();
      expect(row.read<String>('front_folded'), 'công nghệ');
    },
  );
}

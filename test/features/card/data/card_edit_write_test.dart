import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/test_database.dart';
import 'card_batch_writes_fixture.dart';

// The card edit write (BR-CARD-005), all or nothing in one transaction.

DateTime _t0() => DateTime(2026, 9, 23);
final _later = DateTime(2026, 9, 24);

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

void main() {
  useBatchWritesFixture();

  group('editCard (BR-CARD-005)', () {
    test(
      'an edit that expects the version it read goes through; one that '
      'expects an older version is refused and writes nothing (2.18)',
      () async {
        final card = await cards.card(
          nouns.id,
          const CardDraft(front: 'f', back: 'b'),
        );
        // Another device saves first.
        await cards.editCard(
          cardId: card.id,
          draft: const CardDraft(front: 'f', back: 'theirs'),
          now: _later,
        );

        final stale = await cards.editCard(
          cardId: card.id,
          draft: const CardDraft(front: 'f', back: 'mine'),
          expectedUpdatedAt: card.updatedAt,
          now: DateTime(2026, 9, 25),
        );

        expect(_reason(stale), CardRejection.changedElsewhere);
        expect((await cardRow(card.id))['back'], 'theirs');

        final current = await cards.editCard(
          cardId: card.id,
          draft: const CardDraft(front: 'f', back: 'mine'),
          expectedUpdatedAt: _later,
          now: DateTime(2026, 9, 25),
        );
        expect(current, isA<Ok<void, CardRejection>>());
        expect((await cardRow(card.id))['back'], 'mine');
      },
    );

    test('without an expected version the edit overwrites the newer one '
        '("Keep mine", 2.18)', () async {
      final card = await cards.card(
        nouns.id,
        const CardDraft(front: 'f', back: 'b'),
      );
      await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(front: 'f', back: 'theirs'),
        now: _later,
      );

      final result = await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(front: 'f', back: 'mine'),
        now: DateTime(2026, 9, 25),
      );

      expect(result, isA<Ok<void, CardRejection>>());
      expect((await cardRow(card.id))['back'], 'mine');
    });

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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../support/invariant_queries.dart';
import '../support/test_database.dart';

void main() {
  test(
    'deck -> tagged card -> two reviews -> reset leaves a consistent database',
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);
      final now = DateTime(2026, 9, 23);
      final decks = DeckRepositoryImpl(db, now: () => now);
      final schedules = ScheduleRepositoryImpl(db, now: () => now);
      final cards = CardRepositoryImpl(
        db,
        schedules,
        TagRepositoryImpl(db, now: () => now),
        now: () => now,
      );

      final root = ((await decks.createRootDeck(
        name: 'Korean',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final leaf = ((await decks.createSubDeck(
        parentId: root.id,
        name: 'Nouns',
      )) as Ok<DeckEntity, DeckRejection>).value;
      final card = ((await cards.createCard(
        deckId: leaf.id,
        draft: const CardDraft(front: '사과', back: 'apple', tagNames: ['fruit']),
      )) as Ok<CardEntity, CardRejection>).value;

      const sessionId = 'smoke-session';
      await db.customStatement(
        "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, "
        "status, cursor, card_limit, started_at) VALUES (?, ?, ?, 1, 'learning', 'self_assess', "
        "'in_progress', 0, 20, 0)",
        [sessionId, leaf.id, root.id],
      );

      expect(
        await schedules.recordReview(
          cardId: card.id,
          sessionId: sessionId,
          action: EightBoxAction.remembered,
        ),
        isA<Ok<void, SrsRejection>>(),
      );
      expect(
        await schedules.recordReview(
          cardId: card.id,
          sessionId: sessionId,
          action: EightBoxAction.remembered,
        ),
        isA<Ok<void, SrsRejection>>(),
      );
      expect(
        await schedules.resetLearning(rootDeckId: root.id),
        isA<Ok<void, SrsRejection>>(),
      );

      // A reset keeps the review log (BR-SRS-023).
      final logs = await db
          .customSelect('SELECT generation FROM review_log')
          .get();
      expect([for (final log in logs) log.read<int>('generation')], [1, 1]);

      // Every invariant query of schema.md still returns no row, 25 included:
      // it weighs only the turns of the card's current generation.
      for (final MapEntry(key: number, value: query)
          in invariantQueries.entries) {
        final rows = await db.customSelect(query).get();
        expect(
          rows,
          isEmpty,
          reason: 'invariant $number: ${invariantSummaries[number]}',
        );
      }
    },
  );
}

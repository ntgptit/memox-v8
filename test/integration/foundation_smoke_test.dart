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
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../support/invariant_queries.dart';
import '../support/test_database.dart';

void main() {
  test('deck -> tagged card -> learned, then reviewed -> reset leaves a '
      'consistent database', () async {
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

    // A learning session finishes the card, then a review session answers
    // it on schedule (BR-STUDY-051, BR-STUDY-053).
    Future<void> openSession(String id, String kind, String mode) =>
        db.customStatement(
          'INSERT INTO study_session (id, deck_id, root_id, generation, '
          'session_kind, current_mode, status, cursor, card_limit, '
          "started_at) VALUES (?, ?, ?, 1, ?, ?, 'in_progress', 0, 20, 0)",
          [id, leaf.id, root.id, kind, mode],
        );
    ReviewTurn turn(String sessionId, ReviewKind kind) => ReviewTurn(
      cardId: card.id,
      sessionId: sessionId,
      generation: 1,
      kind: kind,
      modeCode: 'recall',
      action: EightBoxAction.remembered,
      answeredAt: now,
    );

    await openSession('learn', 'learning', 'recall');
    expect(
      await schedules.recordTurn(turn('learn', ReviewKind.learning)),
      isA<Ok<void, SrsRejection>>(),
    );
    expect(
      await schedules.completeLearning(cardId: card.id, generation: 1),
      isA<Ok<void, SrsRejection>>(),
    );
    await db.customStatement(
      "UPDATE study_session SET status = 'completed', ended_at = 0 "
      "WHERE id = 'learn'",
    );
    await openSession('review', 'reviewing', 'recall');
    expect(
      await schedules.recordTurn(turn('review', ReviewKind.scheduled)),
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
  });
}

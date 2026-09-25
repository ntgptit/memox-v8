import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/usecases/watch_study_session_use_case.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 6–13 and E5: the read model of the session screen.

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudySessionViewRepositoryImpl views;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    views = StudySessionViewRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudySessionView> viewOf(String sessionId) async =>
      (await views.watchSession(sessionId).first)!;

  Future<(DeckEntity, DeckEntity)> tree([
    SchedulerType type = SchedulerType.eightBox,
  ]) async {
    final root = await decks.root('Korean', type);
    return (root, await decks.sub(root.id, 'Lesson'));
  }

  Future<String> learning(DeckEntity leaf) async =>
      ((await entries.openLearningSession(
        deckId: leaf.id,
      )) as Ok<String, StudyRejection>).value;

  Future<void> answer(String sessionId, StudyAnswer answer) async => expect(
    await sessions.answerTurn(
      sessionId: sessionId,
      cardId: (await servedCard(db, sessionId))!,
      answer: answer,
    ),
    isA<Ok<void, StudyRejection>>(),
  );

  Future<void> deleteCards(Set<String> cardIds) async {
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    );
    expect(
      await cards.deleteCards(cardIds: cardIds),
      isA<Ok<void, CardRejection>>(),
    );
  }

  test('the view names the deck, the kind and the stages, and serves the '
      'head card with the count of its round (IT-MODE-001, '
      'BR-STUDY-049)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b', 'c']) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        front: 'front $id',
        back: 'back $id',
        example: 'example $id',
      );
    }
    final id = await learning(leaf);
    final served = await servedCard(db, id);

    final view = await viewOf(id);

    expect((view.deckId, view.deckName), (leaf.id, 'Lesson'));
    expect(view.kind, SessionKind.learning);
    expect(view.status, SessionStatus.inProgress);
    expect(view.stages, [
      StudyMode.browse,
      StudyMode.match,
      StudyMode.recall,
      StudyMode.fill,
    ]);
    expect((view.currentMode, view.currentStageIndex), (StudyMode.browse, 0));
    final item = view.currentItem!;
    expect(item.cardId, served);
    expect(
      (item.front, item.back, item.example),
      ('front $served', 'back $served', 'example $served'),
    );
    expect((view.currentRound, item.answersInSession), (1, 0));
    expect((view.progress!.completed, view.progress!.total), (0, 3));
    expect(view.isStalled, isFalse);
    expect(view.summary, isNull);
  });

  test('the view emits again after a turn: the next card, the round counted '
      '(BR-STUDY-049)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await learning(leaf);
    final first = (await viewOf(id)).currentItem!.cardId;

    final next = expectLater(
      views.watchSession(id),
      emitsThrough(
        isA<StudySessionView>()
            .having((view) => view.progress?.completed, 'completed', 1)
            .having((view) => view.currentItem?.cardId, 'card', isNot(first)),
      ),
    );
    await answer(id, const AdvanceAnswer());
    await next;
  });

  test('an sm2 self_assess review shows the direction chosen, and each item '
      'its own direction (BR-MODE-015)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.selfAssess,
      direction: DirectionChoice.meaningToKorean,
    );
    final id = (opened as Ok<String, StudyRejection>).value;

    final view = await viewOf(id);

    expect(view.kind, SessionKind.reviewing);
    expect(view.stages, [StudyMode.selfAssess]);
    expect(view.direction, DirectionChoice.meaningToKorean);
    expect(view.currentItem!.cardId, 'a');
    expect(view.currentItem!.direction, QuestionDirection.meaningToKorean);
  });

  test(
    'a completed learning session sums up its cards, the ones that '
    'finished learning and the wrong turns (IT-CONT-005, spec D11)',
    () async {
      final (_, leaf) = await tree(SchedulerType.sm2);
      for (final id in ['c1', 'c2']) {
        await insertCard(db, id: id, deckId: leaf.id);
      }
      final id = await learning(leaf);
      await answer(id, const AdvanceAnswer());
      await answer(id, const AdvanceAnswer());
      await answer(id, const SelfAssessAnswer(Sm2Action.again));
      await answer(id, const SelfAssessAnswer(Sm2Action.good));
      await answer(id, const SelfAssessAnswer(Sm2Action.good));

      final view = await viewOf(id);

      expect(view.status, SessionStatus.completed);
      expect(view.currentItem, isNull);
      expect(view.isStalled, isFalse);
      final summary = view.summary!;
      expect(
        (summary.cardCount, summary.learnedCardCount, summary.wrongTurnCount),
        (2, 2, 1),
      );
    },
  );

  test('a completed review sums up its cards and wrong turns, with no '
      'learned count (IT-REVIEW-009, spec D11)', () async {
    final (root, leaf) = await tree();
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
        box: 3,
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    await answerServed(db, sessions, id, right: false);
    await answerServed(db, sessions, id, right: true);
    await answerServed(db, sessions, id, right: true);

    final summary = (await viewOf(id)).summary!;

    expect(
      (summary.cardCount, summary.learnedCardCount, summary.wrongTurnCount),
      (2, null, 1),
    );
  });

  test('a session whose current cards were deleted is stalled until '
      'Continue settles it (spec D12)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b', 'c']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await learning(leaf);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    await deleteCards({(await servedCard(db, id))!});

    final stalled = await viewOf(id);
    expect(stalled.isStalled, isTrue);
    expect((stalled.currentItem, stalled.progress), (null, null));

    await sessions.resumeSession(sessionId: id);
    final settled = await viewOf(id);
    expect(settled.isStalled, isFalse);
    expect(settled.currentMode, StudyMode.match);
  });

  test('once its deck is deleted the session is notFound, and the watch '
      'says so (UC-STUDY-001 A5, E5; IT-CONT-007)', () async {
    final (_, leaf) = await tree();
    await insertCard(db, id: 'c1', deckId: leaf.id);
    final id = await learning(leaf);
    final watch = WatchStudySessionUseCase(views)(sessionId: id);

    final gone = expectLater(
      watch,
      emitsThrough(
        isA<Rejected<StudySessionView, StudyRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          StudyRejection.notFound,
        ),
      ),
    );
    expect(
      await decks.deleteDeck(deckId: leaf.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await gone;
  });

  test('a read error reaches the watch as a Failure and moves nothing: the '
      'same card is served once the read works again (IT-CONT-013)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await learning(leaf);
    await answer(id, const AdvanceAnswer());
    final served = await servedCard(db, id);
    await db.customStatement('ALTER TABLE card RENAME TO card_unreadable');

    await expectLater(
      views.watchSession(id),
      emitsError(isA<UnknownDatabaseFailure>()),
    );

    await db.customStatement('ALTER TABLE card_unreadable RENAME TO card');
    final view = await viewOf(id);
    expect(view.currentItem!.cardId, served);
    expect((await sessionOf(db, id)).read<int>('cursor'), 1);
  });

  test('a reset of the root while the session is open ends it: the view '
      'reports invalidated/scheduler_reset with its summary, and an answer '
      'is sessionClosed (BR-STUDY-015, UC-SRS-001)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    for (final id in ['c1', 'c2']) {
      await insertCard(db, id: id, deckId: leaf.id);
    }
    final id = await learning(leaf);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    await answer(id, const SelfAssessAnswer(Sm2Action.good));

    expect(
      await ScheduleRepositoryImpl(
        db,
        now: () => now,
      ).resetLearning(rootDeckId: root.id),
      isA<Ok<void, SrsRejection>>(),
    );

    final view = await viewOf(id);
    expect(
      (view.status, view.endReason),
      (SessionStatus.invalidated, SessionEndReason.schedulerReset),
    );
    expect((view.currentItem, view.isStalled), (null, false));
    expect(view.summary!.cardCount, 2);
    final served = await db
        .customSelect(
          "SELECT card_id FROM study_queue_items WHERE status = 'pending'",
        )
        .get();
    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: served.first.read<String>('card_id'),
        answer: const SelfAssessAnswer(Sm2Action.good),
      ),
      isA<Rejected<void, StudyRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        StudyRejection.sessionClosed,
      ),
    );
  });

  test('a card edited during the session shows its new text; the queue '
      'keeps its order (IT-CONT-006)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await learning(leaf);
    final served = (await servedCard(db, id))!;
    final order = await queueOf(db, id, 'browse');
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    );

    expect(
      await cards.editCard(
        cardId: served,
        draft: const CardDraft(front: 'edited', back: 'meaning edited'),
      ),
      isA<Ok<void, CardRejection>>(),
    );

    final item = (await viewOf(id)).currentItem!;
    expect(
      (item.cardId, item.front, item.back),
      (served, 'edited', 'meaning edited'),
    );
    expect(await queueOf(db, id, 'browse'), order);
  });
}

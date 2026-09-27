import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/di/study_session_repository_provider.dart'
    show studySessionRepositoryProvider;
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/study_session_provider.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Spec D4, D5, D12; BR-STUDY-004; UC-STUDY-001 A3, E2.

final _now = DateTime(2026, 9, 24, 9);

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late LockableSessions sessions;

  setUp(() {
    db = openTestDatabase();
    sessions = LockableSessions(studySessionRepository(db, () => _now));
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(_now)),
        studySessionRepositoryProvider.overrideWithValue(sessions),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await expectStudyInvariants(db);
    await db.close();
  });

  /// A root with one sub-deck, the leaf that holds the cards (BR-DECK-004).
  Future<(String, String)> tree() async {
    final decks = DeckRepositoryImpl(db, now: () => _now);
    final root = await decks.root('Korean');
    return (root.id, (await decks.sub(root.id, 'Lesson')).id);
  }

  Future<String> browsing(List<String> ids) async {
    final (_, leaf) = await tree();
    for (final id in ids) {
      await insertCard(db, id: id, deckId: leaf);
    }
    final opened = await studyEntryRepository(
      db,
      () => _now,
    ).openLearningSession(deckId: leaf);
    return (opened as Ok<String, StudyRejection>).value;
  }

  Future<StudySessionController> controllerOf(String id) async {
    container
      ..listen(studySessionControllerProvider(id), (_, _) {})
      ..listen(studySessionProvider(id), (_, _) {});
    await container.read(studySessionProvider(id).future);
    return container.read(studySessionControllerProvider(id).notifier);
  }

  Future<StudyItem> servedOf(String id) async =>
      (await watchSessionOnce(db, id)).currentItem!;

  test('a second command while a write runs is dropped '
      '(BR-STUDY-004)', () async {
    final id = await browsing(['a', 'b', 'c']);
    final controller = await controllerOf(id);
    final item = await servedOf(id);

    await Future.wait([
      controller.answer(item, const AdvanceAnswer()),
      controller.answer(item, const AdvanceAnswer()),
    ]);

    expect((await watchSessionOnce(db, id)).progress!.completed, 1);
    expect(container.read(studySessionControllerProvider(id)).isBusy, isFalse);
  });

  test('a busy database keeps the answer for Retry and moves nothing '
      '(UC-STUDY-001 E2)', () async {
    final id = await browsing(['a', 'b']);
    final controller = await controllerOf(id);
    final item = await servedOf(id);

    sessions.isLocked = true;
    await controller.answer(item, const AdvanceAnswer());
    final state = container.read(studySessionControllerProvider(id));
    expect(state.unsaved?.item.cardId, item.cardId);
    expect((await watchSessionOnce(db, id)).progress!.completed, 0);

    sessions.isLocked = false;
    await controller.retry();
    expect(container.read(studySessionControllerProvider(id)).unsaved, isNull);
    expect((await watchSessionOnce(db, id)).progress!.completed, 1);
  });

  test('a graded turn is held on screen until released (spec D5)', () async {
    final (root, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(
        db,
        id: id,
        deckId: leaf,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 24, 8),
        box: 2,
      );
    }
    await lockScheduler(db, root);
    final opened = await studyEntryRepository(
      db,
      () => _now,
    ).openReviewSession(deckId: leaf, mode: StudyMode.recall);
    final id = (opened as Ok<String, StudyRejection>).value;
    final controller = await controllerOf(id);
    final item = await servedOf(id);

    await controller.answer(
      item,
      // The clock ran out: a graded, wrong turn with no reveal needed.
      const RecallAnswer(RecallOutcome.timedOut),
      shouldHoldFeedback: true,
    );
    final held = container.read(studySessionControllerProvider(id)).held!;
    expect(held.item.cardId, item.cardId);
    expect(held.result.isCorrect, isFalse);

    controller.release();
    expect(container.read(studySessionControllerProvider(id)).held, isNull);
  });

  test('abandon ends the session as user_exit and keeps its turns '
      '(UC-STUDY-001 A3)', () async {
    final id = await browsing(['a', 'b']);
    final controller = await controllerOf(id);
    await controller.answer(await servedOf(id), const AdvanceAnswer());

    await controller.abandon();

    final session = await sessionOf(db, id);
    expect(
      (session.read<String>('status'), session.read<String>('end_reason')),
      ('abandoned', 'user_exit'),
    );
  });

  test('a stalled session settles and serves again (spec D12)', () async {
    final id = await browsing(['a', 'b', 'c']);
    final controller = await controllerOf(id);
    // As watch_session_test does: the round's last card goes.
    await controller.answer(await servedOf(id), const AdvanceAnswer());
    await controller.answer(await servedOf(id), const AdvanceAnswer());
    await hardDeleteCards(db, {(await servedOf(id)).cardId});
    expect((await watchSessionOnce(db, id)).isStalled, isTrue);

    await controller.settle();

    expect((await watchSessionOnce(db, id)).isStalled, isFalse);
  });

  /// A review in `match` of five due cards: one board of five pairs.
  Future<String> matching() async {
    final leaf = await insertFiveDue(
      db,
      DeckRepositoryImpl(db, now: () => _now),
    );
    final opened = await studyEntryRepository(
      db,
      () => _now,
    ).openReviewSession(deckId: leaf.id, mode: StudyMode.match);
    return (opened as Ok<String, StudyRejection>).value;
  }

  test('a match answer names any pending pair of the board, not only the '
      'served one (BR-STUDY-049)', () async {
    final id = await matching();
    final controller = await controllerOf(id);
    final before = await watchSessionOnce(db, id);
    final served = before.currentItem!;
    final other = before.board!.terms
        .firstWhere((tile) => tile.cardId != served.cardId)
        .cardId;

    await controller.answer(served, MatchAnswer(other), cardId: other);

    final after = await watchSessionOnce(db, id);
    expect(
      after.board!.terms.singleWhere((tile) => tile.cardId == other).isMatched,
      isTrue,
    );
    expect(after.currentItem!.cardId, served.cardId);
  });

  test('Retry resends the same pair the busy database refused (E2)', () async {
    final id = await matching();
    final controller = await controllerOf(id);
    final before = await watchSessionOnce(db, id);
    final served = before.currentItem!;
    final other = before.board!.terms
        .firstWhere((tile) => tile.cardId != served.cardId)
        .cardId;

    sessions.isLocked = true;
    await controller.answer(served, MatchAnswer(other), cardId: other);
    sessions.isLocked = false;
    await controller.retry();

    final after = await watchSessionOnce(db, id);
    expect(
      after.board!.terms.singleWhere((tile) => tile.cardId == other).isMatched,
      isTrue,
    );
  });

  /// Two due eight_box cards with an example and a hint, reviewed in [mode].
  Future<String> graded(StudyMode mode) async {
    final (root, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(
        db,
        id: id,
        deckId: leaf,
        example: 'example $id',
        hint: 'hint $id',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 24, 8),
        box: 2,
      );
    }
    await lockScheduler(db, root);
    final opened = await studyEntryRepository(
      db,
      () => _now,
    ).openReviewSession(deckId: leaf, mode: mode);
    return (opened as Ok<String, StudyRejection>).value;
  }

  test('revealing a recall answer keeps its time left and shows it '
      'revealed (FE-A6 P4 R1, BR-STUDY-065)', () async {
    final id = await graded(StudyMode.recall);
    final controller = await controllerOf(id);

    await controller.revealRecall(await servedOf(id), 12000);

    final after = await servedOf(id);
    expect(after.isRevealed, isTrue);
    expect(after.remainingMs, 12000);
    expect(container.read(studySessionControllerProvider(id)).isBusy, isFalse);
  });

  test('a second reveal while the first writes is dropped '
      '(BR-STUDY-004)', () async {
    final id = await graded(StudyMode.recall);
    final controller = await controllerOf(id);
    final item = await servedOf(id);

    await Future.wait([
      controller.revealRecall(item, 12000),
      controller.revealRecall(item, 5000),
    ]);

    expect((await servedOf(id)).remainingMs, 12000);
  });

  test('saving recall time keeps it and never marks a write running '
      '(spec D12)', () async {
    final id = await graded(StudyMode.recall);
    final controller = await controllerOf(id);

    final saving = controller.saveRecallTime(await servedOf(id), 15000);
    expect(container.read(studySessionControllerProvider(id)).isBusy, isFalse);
    await saving;

    expect((await servedOf(id)).remainingMs, 15000);
  });

  test('a time outside the turn is clamped, never thrown (R1)', () async {
    final id = await graded(StudyMode.recall);
    final controller = await controllerOf(id);

    await controller.saveRecallTime(await servedOf(id), -5);

    expect((await servedOf(id)).remainingMs, 0);
  });

  test('showing a fill hint marks it shown (BR-STUDY-028)', () async {
    final id = await graded(StudyMode.fill);
    final controller = await controllerOf(id);

    await controller.showFillHint(await servedOf(id));

    expect((await servedOf(id)).isHintShown, isTrue);
    expect(container.read(studySessionControllerProvider(id)).isBusy, isFalse);
  });
}

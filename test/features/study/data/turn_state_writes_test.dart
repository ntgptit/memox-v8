import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Graded modes spec §8.3: the recall reveal and time and the fill hint are
// writes that are not turns. They record nothing and move nothing.

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<void, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

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

  /// Two due cards under a fresh tree, the first with an example and a hint.
  Future<(DeckEntity, DeckEntity)> twoDue() async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      front: 'Công',
      back: 'work',
      example: 'Đây là một công việc tốt.',
      hint: 'Bắt đầu bằng C',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
    await insertCard(
      db,
      id: 'c2',
      deckId: leaf.id,
      front: 'Nước',
      back: 'water',
      example: 'Uống nước.',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 21),
    );
    await lockScheduler(db, root.id);
    return (root, leaf);
  }

  Future<String> review(String deckId, StudyMode mode) async =>
      ((await entries.openReviewSession(
        deckId: deckId,
        mode: mode,
      )) as Ok<String, StudyRejection>).value;

  Future<int> turnCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  Future<int> cursorOf(String sessionId) async =>
      (await sessionOf(db, sessionId)).read<int>('cursor');

  test('a new recall turn has its full time and its answer hidden '
      '(BR-STUDY-031, BR-STUDY-036)', () async {
    final (_, leaf) = await twoDue();
    final id = await review(leaf.id, StudyMode.recall);

    final item = (await viewOf(id)).currentItem!;
    expect(item.remainingMs, 20000);
    expect(item.isRevealed, isFalse);
  });

  test('revealing the answer records nothing, stops the time and moves '
      'nothing; revealing it again changes nothing (BR-STUDY-065)', () async {
    final (_, leaf) = await twoDue();
    final id = await review(leaf.id, StudyMode.recall);

    expect(
      await sessions.revealRecallAnswer(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 12400,
      ),
      isA<Ok<void, StudyRejection>>(),
    );
    expect(
      await sessions.revealRecallAnswer(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 5000,
      ),
      isA<Ok<void, StudyRejection>>(),
    );

    final item = (await viewOf(id)).currentItem!;
    expect(item.cardId, 'c1');
    expect(item.isRevealed, isTrue);
    expect(item.remainingMs, 12400);
    expect(await turnCount(), 0);
    expect(await cursorOf(id), 0);
  });

  test('the time left is kept for Continue and never grows, and once the '
      'answer is revealed it stays where it stopped (BR-STUDY-036)', () async {
    final (_, leaf) = await twoDue();
    final id = await review(leaf.id, StudyMode.recall);

    await sessions.saveRecallTime(
      sessionId: id,
      cardId: 'c1',
      remainingMs: 15000,
    );
    await sessions.saveRecallTime(
      sessionId: id,
      cardId: 'c1',
      remainingMs: 16000,
    );
    await sessions.resumeSession(sessionId: id);
    expect((await viewOf(id)).currentItem!.remainingMs, 15000);

    await sessions.revealRecallAnswer(
      sessionId: id,
      cardId: 'c1',
      remainingMs: 9000,
    );
    expect(
      await sessions.saveRecallTime(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 3000,
      ),
      isA<Ok<void, StudyRejection>>(),
    );
    expect((await viewOf(id)).currentItem!.remainingMs, 9000);
    expect(await turnCount(), 0);
  });

  test('a shown hint stays on the row and changes nothing else; a card '
      'without a hint has none to show (BR-STUDY-028)', () async {
    final (_, leaf) = await twoDue();
    final id = await review(leaf.id, StudyMode.fill);
    expect((await viewOf(id)).currentItem!.isHintShown, isFalse);

    for (var times = 0; times < 2; times++) {
      expect(
        await sessions.showFillHint(sessionId: id, cardId: 'c1'),
        isA<Ok<void, StudyRejection>>(),
      );
    }
    expect((await viewOf(id)).currentItem!.isHintShown, isTrue);
    expect(await turnCount(), 0);
    expect(await cursorOf(id), 0);

    await db.customStatement("UPDATE card SET hint = NULL WHERE id = 'c1'");
    await db.customStatement(
      "UPDATE study_queue_items SET hint_shown = 0 WHERE card_id = 'c1'",
    );
    expect(
      await sessions.showFillHint(sessionId: id, cardId: 'c1'),
      _refusedWith(StudyRejection.noHint),
    );
  });

  test('each write is refused where a turn would be: another card, another '
      'mode, an ended session, a root reset since (spec §8.3)', () async {
    final (root, leaf) = await twoDue();
    final recall = await review(leaf.id, StudyMode.recall);

    expect(
      await sessions.revealRecallAnswer(
        sessionId: recall,
        cardId: 'c2',
        remainingMs: 1000,
      ),
      _refusedWith(StudyRejection.notCurrentCard),
    );
    expect(
      await sessions.showFillHint(sessionId: recall, cardId: 'c1'),
      _refusedWith(StudyRejection.answerDoesNotFitMode),
    );

    final fill = await review(leaf.id, StudyMode.fill);
    expect(
      await sessions.saveRecallTime(
        sessionId: fill,
        cardId: 'c1',
        remainingMs: 1000,
      ),
      _refusedWith(StudyRejection.answerDoesNotFitMode),
    );
    expect(
      await sessions.revealRecallAnswer(
        sessionId: recall,
        cardId: 'c1',
        remainingMs: 1000,
      ),
      _refusedWith(StudyRejection.sessionClosed),
    );

    await ScheduleRepositoryImpl(
      db,
      now: () => now,
    ).resetLearning(rootDeckId: root.id);
    await db.customUpdate(
      "UPDATE study_session SET status = 'in_progress', end_reason = NULL,"
      ' ended_at = NULL WHERE id = ?',
      variables: [Variable<String>(fill)],
    );
    expect(
      await sessions.showFillHint(sessionId: fill, cardId: 'c1'),
      _refusedWith(StudyRejection.staleGeneration),
    );
    expect(
      (await sessionOf(db, fill)).read<String>('end_reason'),
      'stale_generation',
    );
  });
}

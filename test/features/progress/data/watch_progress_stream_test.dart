import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-PROGRESS-001 A3, A5, A6 and UC-PROGRESS-002 step 6, E1: when `/progress`
// reads again, what a write changes, and a read that fails (Progress spec
// §6.3, §6.4, §6.6).

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (UC-PROGRESS-001 E1).
final class _FailingSelects extends QueryInterceptor {
  bool isArmed = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isArmed) {
      throw SqliteException(extendedResultCode: 10, message: 'disk I/O error');
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ProgressRepositoryImpl progress;
  final now = DateTime(2026, 9, 25, 12);
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  void open([QueryInterceptor? interceptor]) {
    db = openTestDatabase(interceptor: interceptor);
    decks = DeckRepositoryImpl(db, now: () => now);
    progress = ProgressRepositoryImpl(db);
  }

  setUp(() => open());
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<Progress> read() => progress.watchProgress(days).first;

  CardRepositoryImpl cards() => CardRepositoryImpl(
    db,
    ScheduleRepositoryImpl(db, now: () => now),
    TagRepositoryImpl(db, now: () => now),
    now: () => now,
  );

  /// The month's active cards per root deck, in the list's order.
  Map<String, int> monthCards(Progress snapshot) => {
    for (final deck in snapshot.level.decksFor(ProgressRange.month))
      deck.name: deck.progress.month.activeCards,
  };

  test('the snapshot comes again on a new answer, a renamed deck and a '
      'deleted deck (BR-PROGRESS-008)', () async {
    final alpha = await decks.root('Alpha');
    final alphaLesson = await decks.sub(alpha.id, 'Lesson');
    final beta = await decks.root('Beta');
    await learnedCard(db, alphaLesson.id, 'a1');
    await lockScheduler(db, alpha.id);
    final snapshots = <Progress>[];
    final subscription = progress.watchProgress(days).listen(snapshots.add);
    await pumpEventQueue();
    expect(monthCards(snapshots.last), {'Alpha': 0, 'Beta': 0});

    await answer(db, 'a1', hanoi(9, 25, 9));
    await pumpEventQueue();
    expect(monthCards(snapshots.last), {'Alpha': 1, 'Beta': 0});

    expect(
      await decks.renameDeck(deckId: beta.id, name: 'Aardvark'),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(monthCards(snapshots.last), {'Alpha': 1, 'Aardvark': 0});

    expect(
      await decks.deleteDeck(deckId: alpha.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(monthCards(snapshots.last), {'Aardvark': 0});
    expect(snapshots.last.overview.hasLifetimeActivity, isFalse);
    await subscription.cancel();
  });

  test('a sub-deck moved to another root takes its whole history along '
      '(BR-PROGRESS-004)', () async {
    final korean = await decks.root('Korean');
    final english = await decks.root('English');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await decks.sub(english.id, 'Words');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await lockScheduler(db, english.id);
    await answer(db, 'c1', hanoi(9, 10, 9));
    await answer(db, 'c1', hanoi(9, 25, 9));

    expect(
      await decks.moveDeck(deckId: lesson.id, newParentId: english.id),
      isA<Ok<void, DeckRejection>>(),
    );
    final snapshot = await read();

    expect(monthCards(snapshot), {'English': 1, 'Korean': 0});
    expect(
      snapshot.level
          .decksFor(ProgressRange.month)
          .first
          .progress
          .month
          .cardDays,
      2,
    );
  });

  test('a deleted card takes its history away, past days included '
      '(BR-PROGRESS-017; UC-PROGRESS-001 A6)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await learnedCard(db, lesson.id, 'c2');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 1, 9));
    await answer(db, 'c2', hanoi(9, 25, 9));

    expect(
      await cards().deleteCards(cardIds: {'c1'}),
      isA<Ok<void, CardRejection>>(),
    );
    final snapshot = await read();

    expect(snapshot.level.total.month.cardDays, 1);
    expect(snapshot.overview.streak.days, 1);
  });

  test('a reset of learning progress changes no number (BR-PROGRESS-017; '
      'UC-PROGRESS-001 A5)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 24, 9));
    await answer(db, 'c1', hanoi(9, 25, 9));
    final before = await read();

    expect(
      await ScheduleRepositoryImpl(
        db,
        now: () => now,
      ).resetLearning(rootDeckId: korean.id),
      isA<Ok<void, SrsRejection>>(),
    );
    final after = await read();

    expect(after.level.total.month.cardDays, before.level.total.month.cardDays);
    expect(after.overview.streak.days, 2);
  });

  test('reading writes nothing and opens no session (BR-PROGRESS-007, '
      'BR-PROGRESS-009; the backend half of IT-NAV-011 step 2)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 25, 9));
    final before = await totalChanges(db);

    await read();

    expect(await totalChanges(db), before);
    final sessions = await db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });

  test('opening Progress while a study session is open leaves it open and '
      'writes nothing (BR-PROGRESS-009; IT-NAV-011 step 2)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await insertCard(db, id: 'new', deckId: lesson.id, back: 'new');
    final opened = await studyEntryRepository(
      db,
      () => now,
    ).openLearningSession(deckId: lesson.id);
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    final before = await totalChanges(db);

    await read();

    expect(await totalChanges(db), before);
    expect(
      (await sessionOf(db, sessionId)).read<String>('status'),
      'in_progress',
    );
  });

  test(
    'a read that fails comes as a database Failure (UC-PROGRESS-001 E1)',
    () async {
      await db.close();
      final failing = _FailingSelects();
      open(failing);
      await decks.root('Korean');
      failing.isArmed = true;

      await expectLater(
        progress.watchProgress(days),
        emitsError(isA<Failure>()),
      );
      failing.isArmed = false;
    },
  );
}

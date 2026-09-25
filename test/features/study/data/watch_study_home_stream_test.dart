import 'dart:async';

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
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-002 step 5 and E1: when the Study tab reads again, and a read
// that fails (Study Home spec §6.3, §6.5).

/// Completes [started] when the Study tab's snapshot reads the sessions, so a
/// test can write while that read runs.
final class _SessionReadSignal extends QueryInterceptor {
  final started = Completer<void>();

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (!started.isCompleted && statement.contains('FROM study_session s')) {
      started.complete();
    }
    return super.runSelect(executor, statement, args);
  }
}

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (UC-STUDY-002 E1).
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
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudyHomeRepositoryImpl home;
  final now = DateTime(2026, 9, 25, 9);
  final today = DateTime(2026, 9, 25);

  void open([QueryInterceptor? interceptor]) {
    db = openTestDatabase(interceptor: interceptor);
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    home = StudyHomeRepositoryImpl(db);
  }

  setUp(() => open());
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  String opened(Outcome<String, StudyRejection> outcome) =>
      (outcome as Ok<String, StudyRejection>).value;

  CardRepositoryImpl cardRepository() => CardRepositoryImpl(
    db,
    ScheduleRepositoryImpl(db, now: () => now),
    TagRepositoryImpl(db, now: () => now),
    now: () => now,
  );

  List<String> namesOf(StudyHome snapshot) => [
    for (final deck in (snapshot.content as RootDeckWorkload).decks) deck.name,
  ];

  /// A learned card of [deckId] due at [dueAt], of its own meaning.
  Future<void> learned(String deckId, String id, DateTime dueAt) => insertCard(
    db,
    id: id,
    deckId: deckId,
    back: 'meaning $id',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 2,
  );

  test('the snapshot comes again when a turn is answered and when the '
      'session is left (UC-STUDY-002 step 5)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await learned(lesson.id, 'a', DateTime(2026, 9, 24));
    await learned(lesson.id, 'b', DateTime(2026, 9, 24));
    await lockScheduler(db, root.id);
    final id = opened(
      await entries.openReviewSession(
        deckId: lesson.id,
        mode: StudyMode.recall,
      ),
    );
    final homes = <StudyHome>[];
    final subscription = home
        .watchHome(now: now, startOfToday: today)
        .listen(homes.add);
    await pumpEventQueue();
    expect(homes.last.resumable?.progress?.completed, 0);

    await answerServed(db, sessions, id, right: true);
    await pumpEventQueue();
    expect(homes.last.resumable?.progress?.completed, 1);
    expect((homes.last.content as RootDeckWorkload).overdueCount, 1);

    await sessions.abandonSession(sessionId: id);
    await pumpEventQueue();
    expect(homes.last.resumable, isNull);
    await subscription.cancel();
  });

  test(
    'a write made while the first read runs is not lost (spec D7)',
    () async {
      await db.close();
      final signal = _SessionReadSignal();
      open(signal);
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id, back: 'one');
      final id = opened(await entries.openLearningSession(deckId: lesson.id));
      final homes = <StudyHome>[];

      final subscription = home
          .watchHome(now: now, startOfToday: today)
          .listen(homes.add);
      await signal.started.future;
      await sessions.abandonSession(sessionId: id);
      await pumpEventQueue();

      expect(homes.first.resumable?.sessionId, id);
      expect(homes.last.resumable, isNull);
      await subscription.cancel();
    },
  );

  test('a write of several rows in one transaction reads the tab again once '
      '(spec D7)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    for (final id in ['c1', 'c2', 'c3']) {
      await insertCard(db, id: id, deckId: lesson.id, back: id);
    }
    final homes = <StudyHome>[];
    final subscription = home
        .watchHome(now: now, startOfToday: today)
        .listen(homes.add);
    await pumpEventQueue();
    final before = homes.length;

    expect(
      await cardRepository().deleteCards(cardIds: {'c1', 'c2'}),
      isA<Ok<void, CardRejection>>(),
    );
    await pumpEventQueue();

    expect(homes.length, before + 1);
    expect((homes.last.content as RootDeckWorkload).newCount, 1);
    await subscription.cancel();
  });

  test('a deck renamed while the tab is open takes its new place in the list '
      '(BR-STUDY-076)', () async {
    final alpha = await decks.root('Alpha');
    final beta = await decks.root('Beta');
    final a = await decks.sub(alpha.id, 'A');
    final b = await decks.sub(beta.id, 'B');
    await insertCard(db, id: 'a1', deckId: a.id, back: 'one');
    await insertCard(db, id: 'b1', deckId: b.id, back: 'two');
    final homes = <StudyHome>[];
    final subscription = home
        .watchHome(now: now, startOfToday: today)
        .listen(homes.add);
    await pumpEventQueue();
    expect(namesOf(homes.last), ['Alpha', 'Beta']);

    expect(
      await decks.renameDeck(deckId: alpha.id, name: 'Zulu'),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();

    expect(namesOf(homes.last), ['Beta', 'Zulu']);
    await subscription.cancel();
  });

  test(
    'a read that fails comes as a database Failure (UC-STUDY-002 E1)',
    () async {
      await db.close();
      final failing = _FailingSelects();
      open(failing);
      await decks.root('Korean');
      failing.isArmed = true;

      await expectLater(
        home.watchHome(now: now, startOfToday: today),
        emitsError(isA<Failure>()),
      );
      failing.isArmed = false;
    },
  );
}

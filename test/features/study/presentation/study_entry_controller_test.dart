import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Screen 14's starts: UC-STUDY-001 steps 3–5, A3b; UC-STUDY-003;
// BR-STUDY-004, BR-STUDY-018.

void main() {
  late LibraryEnv env;
  setUp(() => env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday)));
  tearDown(() async {
    await expectStudyInvariants(env.db);
    await env.db.close();
  });

  late ProviderContainer container;

  StudyEntryController controllerOf(String leaf) {
    container = libraryContainer(env)
      ..listen(studyEntryControllerProvider(leaf), (_, _) {});
    return container.read(studyEntryControllerProvider(leaf).notifier);
  }

  StudyStartState stateOf(String leaf) =>
      container.read(studyEntryControllerProvider(leaf));

  test('Learn opens a learning session and answers its id', () async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2);
    final controller = controllerOf(leaf);

    final id = await controller.start(const LearnStart());

    expect(
      (await sessionOf(env.db, id!)).read<String>('session_kind'),
      'learning',
    );
    expect(stateOf(leaf).status, StudyStartStatus.idle);
  });

  test('Review opens a self-assess review in the chosen direction', () async {
    final leaf = await sm2Leaf(env.db, env.decks, dueCards: 2);

    final id = await controllerOf(leaf).start(
      const ReviewStart(
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.meaningToKorean,
      ),
    );

    expect(
      (await sessionOf(env.db, id!)).read<String>('direction'),
      'meaning_to_korean',
    );
  });

  test('a second start while one runs is dropped (BR-STUDY-004)', () async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2, dueCards: 2);
    final controller = controllerOf(leaf);

    final first = controller.start(const LearnStart());
    final second = await controller.start(
      const ReviewStart(
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.mixed,
      ),
    );
    await first;

    expect(second, isNull);
    expect(env.entries.opened, 1);
  });

  test('self-assess no longer offered is refused as a change meanwhile, '
      'not a failed start (UC-STUDY-003 E1)', () async {
    final leaf = await sm2Leaf(env.db, env.decks, dueCards: 2);
    final controller = controllerOf(leaf);
    // The root's scheduler changed while the direction sheet was open.
    await env.db.customStatement(
      "UPDATE deck SET scheduler_type = 'eight_box' "
      'WHERE scheduler_type IS NOT NULL',
    );

    final id = await controller.start(
      const ReviewStart(
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.mixed,
      ),
    );

    expect(id, isNull);
    expect(stateOf(leaf).status, StudyStartStatus.refused);
    expect(stateOf(leaf).refusal, StudyRejection.modeNotOffered);
    // Back to the scheduler its cards follow, for the teardown's invariants.
    await env.db.customStatement(
      "UPDATE deck SET scheduler_type = 'sm2' WHERE scheduler_type IS NOT NULL",
    );
  });

  test('nothing left to review is refused, with its reason', () async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);
    final controller = controllerOf(leaf);

    final id = await controller.start(
      const ReviewStart(
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.mixed,
      ),
    );

    expect(id, isNull);
    expect(stateOf(leaf).status, StudyStartStatus.refused);
    expect(stateOf(leaf).refusal, StudyRejection.nothingDue);
  });

  test(
    'a failed write is startFailed; Try again repeats the same start',
    () async {
      final leaf = await sm2Leaf(env.db, env.decks, dueCards: 1);
      final controller = controllerOf(leaf);
      env.entries.isFailing = true;

      final failed = await controller.start(
        const ReviewStart(
          mode: StudyMode.selfAssess,
          direction: DirectionChoice.meaningToKorean,
        ),
      );

      expect(failed, isNull);
      expect(stateOf(leaf).status, StudyStartStatus.failed);

      env.entries.isFailing = false;
      final id = await controller.retry();

      expect(
        (await sessionOf(env.db, id!)).read<String>('direction'),
        'meaning_to_korean',
      );
    },
  );

  test(
    'Continue resumes the session and answers its id (UC-STUDY-001 A3b)',
    () async {
      final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);
      final opened = await env.entries.openLearningSession(deckId: leaf);
      final sessionId = (opened as Ok<String, StudyRejection>).value;

      expect(
        await controllerOf(leaf).start(ContinueStart(sessionId)),
        sessionId,
      );
    },
  );

  test('Continue on a session that ended meanwhile is refused', () async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);
    final opened = await env.entries.openLearningSession(deckId: leaf);
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    await env.sessions.abandonSession(sessionId: sessionId);
    final controller = controllerOf(leaf);

    expect(await controller.start(ContinueStart(sessionId)), isNull);
    expect(stateOf(leaf).status, StudyStartStatus.refused);
    expect(stateOf(leaf).refusal, StudyRejection.sessionClosed);
  });

  test("another deck's open session asks first; Keep it starts nothing and "
      'writes nothing (R3, 2.01)', () async {
    final other = await openOtherDeckSession(env.db, env.decks, env.entries);
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);
    final asked = <String>[];

    final id = await controllerOf(leaf).start(
      const LearnStart(),
      confirmEnd: (deckName) async {
        asked.add(deckName);
        return false;
      },
    );

    expect(id, isNull);
    expect(asked, ['Unit']);
    expect(stateOf(leaf).status, StudyStartStatus.idle);
    expect(
      (await sessionOf(env.db, other)).read<String>('status'),
      'in_progress',
    );
    // Only the other deck's opening reached the store.
    expect(env.entries.opened, 1);
  });

  test("End it and start closes the other deck's session and opens the new "
      'one (R3, 2.01)', () async {
    final other = await openOtherDeckSession(env.db, env.decks, env.entries);
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);

    final id = await controllerOf(leaf)
        .start(const LearnStart(), confirmEnd: (_) async => true);

    expect(id, isNotNull);
    final ended = await sessionOf(env.db, other);
    expect(
      (ended.read<String>('status'), ended.read<String>('end_reason')),
      ('abandoned', 'user_exit'),
    );
  });

  test('a start on the deck that holds the open session asks nothing '
      '(spec 3.1, 2.01)', () async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2);
    await env.entries.openLearningSession(deckId: leaf);

    final id = await controllerOf(leaf).start(
      const LearnStart(),
      confirmEnd: (_) async => fail("asked about the deck's own session"),
    );

    expect(id, isNotNull);
  });

  test('a failed check of the other session does not hold the start back '
      '(R3, 2.01)', () async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);
    env.entries.isOtherSessionReadFailing = true;

    final id = await controllerOf(
      leaf,
    ).start(const LearnStart(), confirmEnd: (_) async => fail('must not ask'));

    expect(id, isNotNull);
    expect(stateOf(leaf).status, StudyStartStatus.idle);
  });

  test("another deck's session left open on an earlier day is closed as "
      'stale and never asks (R3, 2.01 review focus)', () async {
    final other = await openOtherDeckSession(
      env.db,
      env.decks,
      env.entries,
      at: DateTime(2026, 9, 23, 9),
    );
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);

    final id = await controllerOf(
      leaf,
    ).start(const LearnStart(), confirmEnd: (_) async => fail('must not ask'));

    expect(id, isNotNull);
    final closed = await sessionOf(env.db, other);
    expect(
      (closed.read<String>('status'), closed.read<String>('end_reason')),
      ('abandoned', 'interrupted'),
    );
  });
}

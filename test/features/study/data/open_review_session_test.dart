import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 step 4 and UC-STUDY-003: opening a review session.

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<String, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

String _opened(Outcome<String, StudyRejection> result) => switch (result) {
  Ok(:final value) => value,
  Rejected(:final reason) => fail('opening refused: $reason'),
};

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// A root [name] running [scheduler] and its sub-deck `Lesson`.
  Future<(DeckEntity, DeckEntity)> tree([
    SchedulerType scheduler = SchedulerType.eightBox,
    String name = 'Korean',
  ]) async {
    final root = await decks.root(name, scheduler);
    return (root, await decks.sub(root.id, 'Lesson'));
  }

  /// A learned card of [deckId] due at [dueAt], of its own meaning, and the
  /// lock its learning left on [rootId] (BR-SRS-003).
  Future<void> learned(
    String rootId,
    String deckId,
    String id,
    DateTime dueAt, {
    bool withExample = false,
  }) async {
    await insertCard(
      db,
      id: id,
      deckId: deckId,
      back: 'meaning of $id',
      example: withExample ? 'example of $id' : null,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: dueAt,
    );
    await lockScheduler(db, rootId);
  }

  Future<List<String?>> directionsOf(String sessionId) async => [
    for (final row
        in await db
            .customSelect(
              'SELECT direction FROM study_queue_items WHERE session_id = ? '
              'ORDER BY position',
              variables: [Variable(sessionId)],
            )
            .get())
      row.read<String?>('direction'),
  ];

  test('a review takes the due cards of the subtree, earliest due first, up '
      'to the limit, in the mode picked (IT-REVIEW-001, IT-REVIEW-002, '
      'IT-REVIEW-004, BR-STUDY-002)', () async {
    final (root, leaf) = await tree();
    for (final (id, day) in [('d4', 23), ('d1', 20), ('d3', 22), ('d2', 21)]) {
      await learned(root.id, leaf.id, id, DateTime(2026, 9, day));
    }
    await learned(root.id, leaf.id, 'later', DateTime(2026, 9, 25));
    await insertCard(db, id: 'new', deckId: leaf.id);
    await SettingsRepositoryImpl(db, now: () => now).saveRootStudyOptions(
      rootDeckId: root.id,
      options: const StudyOptions(
        cardLimit: 3,
        newCardOrder: NewCardOrder.created,
      ),
    );

    final id = _opened(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.recall),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('session_kind'), 'reviewing');
    expect(session.read<String>('current_mode'), 'recall');
    expect(session.read<int>('card_limit'), 3);
    expect(session.data['direction'], isNull);
    expect(await modesOf(db, id), ['recall']);
    expect(await queueOf(db, id, 'recall'), ['d1', 'd2', 'd3']);
  });

  test('fill reviews the due cards with an example, and a mode that cannot '
      'run on the due cards is refused (BR-STUDY-044, BR-MODE-009; '
      'IT-STUDY-006, IT-STUDY-007)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    await learned(
      root.id,
      leaf.id,
      'b',
      DateTime(2026, 9, 21),
      withExample: true,
    );
    final before = await totalChanges(db);

    expect(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.guess),
      _refusedWith(StudyRejection.modeUnavailable),
    );
    expect(await totalChanges(db), before);
    final id = _opened(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.fill),
    );
    expect(await queueOf(db, id, 'fill'), ['b']);
  });

  test('match needs two due cards (BR-STUDY-045)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));

    expect(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.match),
      _refusedWith(StudyRejection.modeUnavailable),
    );
  });

  test('a mode the algorithm does not offer for a review is refused '
      '(BR-STUDY-055)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    final (sm2Root, sm2Leaf) = await tree(SchedulerType.sm2, 'Other');
    await learned(sm2Root.id, sm2Leaf.id, 's', DateTime(2026, 9, 20));

    for (final (deckId, mode) in [
      (root.id, StudyMode.browse),
      (root.id, StudyMode.selfAssess),
      (sm2Root.id, StudyMode.recall),
    ]) {
      expect(
        await entries.openReviewSession(deckId: deckId, mode: mode),
        _refusedWith(StudyRejection.modeNotOffered),
      );
    }
  });

  test('nothing due is refused, writing nothing: no review before its time '
      '(BR-STUDY-054; IT-STUDY-003, IT-REVIEW-008)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'later', DateTime(2026, 9, 25));
    await insertCard(db, id: 'new', deckId: leaf.id);
    final before = await totalChanges(db);

    expect(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.recall),
      _refusedWith(StudyRejection.nothingDue),
    );
    expect(await totalChanges(db), before);
  });

  test('an sm2 review needs a direction: none is a validation error that '
      'writes nothing (BR-MODE-013, BR-MODE-018; UC-STUDY-003 E3)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    final before = await totalChanges(db);

    expect(
      await entries.openReviewSession(
        deckId: root.id,
        mode: StudyMode.selfAssess,
      ),
      _refusedWith(StudyRejection.directionRequired),
    );
    expect(await totalChanges(db), before);
  });

  test('a direction where none is taken is a conflict that writes nothing '
      '(BR-MODE-013, BR-MODE-018)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    final before = await totalChanges(db);

    expect(
      await entries.openReviewSession(
        deckId: root.id,
        mode: StudyMode.recall,
        direction: DirectionChoice.koreanToMeaning,
      ),
      _refusedWith(StudyRejection.directionNotAllowed),
    );
    expect(await totalChanges(db), before);
  });

  test('a fixed direction is stored on the session and on every row '
      '(BR-MODE-015, BR-MODE-016; UC-STUDY-003 step 5)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await learned(root.id, leaf.id, id, DateTime(2026, 9, day));
    }

    final id = _opened(
      await entries.openReviewSession(
        deckId: root.id,
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.meaningToKorean,
      ),
    );

    expect(
      (await sessionOf(db, id)).read<String>('direction'),
      'meaning_to_korean',
    );
    expect(await directionsOf(id), ['meaning_to_korean', 'meaning_to_korean']);
  });

  test('mixed gives each row one direction, split evenly, and stores mixed '
      'on the session only (BR-MODE-015)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    for (final (id, day) in [('a', 20), ('b', 21), ('c', 22)]) {
      await learned(root.id, leaf.id, id, DateTime(2026, 9, day));
    }

    final id = _opened(
      await entries.openReviewSession(
        deckId: root.id,
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.mixed,
      ),
    );

    expect((await sessionOf(db, id)).read<String>('direction'), 'mixed');
    final directions = await directionsOf(id);
    expect(directions, isNot(contains('mixed')));
    final koreanFirst = directions
        .where((direction) => direction == 'korean_to_meaning')
        .length;
    expect(koreanFirst, anyOf(1, 2));
    expect(directions, hasLength(3));
  });

  test('a review closes the open learning session of the same day as the '
      "person's exit (IT-CONT-014, spec D2)", () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    await insertCard(db, id: 'new', deckId: leaf.id);
    final learning = _opened(
      await entries.openLearningSession(deckId: leaf.id),
    );

    final review = _opened(
      await entries.openReviewSession(deckId: leaf.id, mode: StudyMode.recall),
    );

    final closed = await sessionOf(db, learning);
    expect(closed.read<String>('status'), 'abandoned');
    expect(closed.read<String>('end_reason'), 'user_exit');
    expect(
      (await sessionOf(db, review)).read<String>('session_kind'),
      'reviewing',
    );
  });
}

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 A0, A0c and A1 on eight_box decks: the graded modes' rounds,
// answered right or wrong with each mode's own input (graded modes spec §7.1).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<DeckEntity> lesson() async {
    final root = await decks.root('Korean');
    return decks.sub(root.id, 'Lesson');
  }

  Future<String> openLearning(String deckId) async =>
      ((await entries.openLearningSession(
        deckId: deckId,
      )) as Ok<String, StudyRejection>).value;

  Future<String> modeOf(String sessionId) async =>
      (await sessionOf(db, sessionId)).read<String>('current_mode');

  /// Answers [card], or the card served, right or wrong.
  Future<void> graded(String sessionId, {required bool right, String? card}) =>
      answerServed(db, sessions, sessionId, right: right, cardId: card);

  /// Answers right until the session leaves [mode].
  Future<void> passStage(String sessionId, String mode) async {
    while (await modeOf(sessionId) == mode &&
        (await sessionOf(db, sessionId)).read<String>('status') ==
            'in_progress') {
      await graded(sessionId, right: true);
    }
  }

  test('a wrong card joins the next round once; each round has its own order '
      'and a clean round ends the stage, with no cap (IT-LEARN-008, '
      'BR-STUDY-059, BR-STUDY-060, BR-STUDY-061, BR-STUDY-069)', () async {
    final leaf = await lesson();
    for (final id in ['a', 'b', 'c']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await openLearning(leaf.id);
    await passStage(id, 'browse');
    await passStage(id, 'match');
    expect(await modeOf(id), 'recall');
    final roundOne = await queueOf(db, id, 'recall');

    await graded(id, right: false);
    await graded(id, right: false);
    await graded(id, right: true);
    final roundTwo = await queueOf(db, id, 'recall', round: 2);
    await graded(id, right: false, card: roundTwo.first);
    await graded(id, right: true, card: roundTwo.last);
    await graded(id, right: true);

    expect(roundTwo..sort(), roundOne.sublist(0, 2)..sort());
    expect(
      await queueOf(db, id, 'recall', round: 2),
      isNot(roundOne.sublist(0, 2)),
      reason: 'round 2 is not round 1 again (BR-STUDY-061)',
    );
    expect(await queueOf(db, id, 'recall', round: 3), hasLength(1));
    expect(await queueOf(db, id, 'recall', round: 4), isEmpty);
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    // match, then recall rounds 1, 2 and 3: only its first turn in each
    // stage is `learning` (BR-STUDY-023; spec D8).
    expect(await turnKindsOf(db, roundOne[1]), [
      'learning',
      'learning',
      'relearning',
      'relearning',
    ]);
  });

  test(
    'a wrong match stays on the board and joins the next round once, '
    'even when matched right afterwards (BR-STUDY-062, BR-STUDY-060)',
    () async {
      final leaf = await lesson();
      for (final id in ['a', 'b']) {
        await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
      }
      final id = await openLearning(leaf.id);
      await passStage(id, 'browse');
      expect(await modeOf(id), 'match');

      await graded(id, right: false, card: 'b');
      await graded(id, right: false, card: 'b');
      await graded(id, right: true, card: 'b');
      await graded(id, right: true, card: 'a');

      expect(await queueOf(db, id, 'match', round: 2), ['b']);
      expect(await modeOf(id), 'match');
      await graded(id, right: true, card: 'b');
      expect(await modeOf(id), 'recall');
    },
  );

  test('a card finishes learning when it passes the last stage it takes '
      'part in: a card skipped in fill finishes at recall (IT-LEARN-005, '
      'BR-STUDY-053, BR-STUDY-071)', () async {
    final leaf = await lesson();
    await insertCard(db, id: 'plain', deckId: leaf.id, back: 'plain');
    await insertCard(
      db,
      id: 'rich',
      deckId: leaf.id,
      back: 'rich',
      example: 'an example',
    );
    final id = await openLearning(leaf.id);
    for (final mode in ['browse', 'match', 'recall']) {
      await passStage(id, mode);
    }

    expect(await modeOf(id), 'fill');
    expect((await scheduleRowOf(db, 'plain')).data['learned_at'], isNotNull);
    expect((await scheduleRowOf(db, 'rich')).data['learned_at'], isNull);
    await passStage(id, 'fill');
    expect((await scheduleRowOf(db, 'rich')).data['learned_at'], isNotNull);
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
  });

  test('in an eight_box review a wrong first turn sends the card to box 1, '
      'and its next round relearns it without moving it again '
      '(IT-REVIEW-005, IT-REVIEW-006, BR-SRS-008, BR-STUDY-023)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        back: 'meaning $id',
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

    await graded(id, right: false, card: 'a');
    await graded(id, right: true, card: 'b');
    await graded(id, right: true, card: 'a');

    final a = await scheduleRowOf(db, 'a');
    expect(a.read<int>('current_box'), 1);
    expect(a.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    expect((a.read<int>('answer_count'), a.read<int>('lapse_count')), (1, 1));
    final b = await scheduleRowOf(db, 'b');
    expect(b.read<int>('current_box'), 4);
    expect(b.read<DateTime>('due_at'), DateTime(2026, 10, 2));
    expect(await turnKindsOf(db, 'a'), ['scheduled', 'relearning']);
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    final logs = await db
        .customSelect(
          'SELECT mode FROM review_log WHERE session_id = ?',
          variables: [Variable(id)],
        )
        .get();
    expect({for (final log in logs) log.read<String>('mode')}, {'recall'});
  });
}

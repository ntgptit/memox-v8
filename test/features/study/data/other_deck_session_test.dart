import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// R3 (SP2a 2.01): the open session of another deck that a start would end.

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

  /// Korean > Lesson and Spanish > Unit with one new card each; returns the
  /// two leaves' ids.
  Future<(String, String)> twoLeaves() async {
    final korean = await decks.root('Korean', SchedulerType.sm2);
    final lesson = await decks.sub(korean.id, 'Lesson');
    final spanish = await decks.root('Spanish', SchedulerType.sm2);
    final unit = await decks.sub(spanish.id, 'Unit');
    await insertCard(db, id: 'a1', deckId: lesson.id);
    await insertCard(db, id: 'b1', deckId: unit.id);
    return (lesson.id, unit.id);
  }

  Future<String> openOn(String deckId, {DateTime? at}) async {
    final opened = await entries.openLearningSession(deckId: deckId, now: at);
    return (opened as Ok<String, StudyRejection>).value;
  }

  test("names the deck of another deck's open session", () async {
    final (lesson, unit) = await twoLeaves();
    await openOn(lesson);

    expect(
      await entries.otherDeckSessionName(deckId: unit, now: now),
      'Lesson',
    );
  });

  test('the deck that holds the session is not asked about itself', () async {
    final (lesson, _) = await twoLeaves();
    await openOn(lesson);

    expect(
      await entries.otherDeckSessionName(deckId: lesson, now: now),
      isNull,
    );
  });

  test('no session, an ended one and one of an earlier day ask nothing', () async {
    final (lesson, unit) = await twoLeaves();
    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);

    final ended = await openOn(lesson);
    await studySessionRepository(
      db,
      () => now,
    ).abandonSession(sessionId: ended);
    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);

    await openOn(lesson, at: DateTime(2026, 9, 23, 9));
    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);
    // Close the stale one, so the teardown's one-open-session invariant holds.
    await studySessionRepository(db, () => now).abandonStaleSessions(now: now);
  });

  test("a session whose deck went to the Trash is not offered", () async {
    final (lesson, unit) = await twoLeaves();
    await openOn(lesson);

    await decks.deleteDeck(deckId: lesson);

    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);
  });

  test('a session of another deck left open on an earlier day is closed as '
      'stale before entry and never asks (SP2a 2.01 review focus)', () async {
    final (lesson, unit) = await twoLeaves();
    final stale = await openOn(lesson, at: DateTime(2026, 9, 23, 9));

    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);

    // Starting on the other deck closes the stale session as interrupted
    // (BR-STUDY-072) and opens the new one.
    await openOn(unit);
    final row = await sessionOf(db, stale);
    expect(
      (row.read<String>('status'), row.read<String>('end_reason')),
      ('abandoned', 'interrupted'),
    );
  });
}

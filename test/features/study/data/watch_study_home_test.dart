import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-STUDY-002 steps 1–3: what the Study tab's snapshot holds (Study Home
// spec §5, §6.1).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudyHomeRepositoryImpl home;
  final now = DateTime(2026, 9, 25, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    home = StudyHomeRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudyHome> homeAt([DateTime? at]) {
    final time = at ?? now;
    return home.watchHome(now: time, startOfToday: startOfLocalDay(time)).first;
  }

  Future<RootDeckWorkload> workload() async =>
      (await homeAt()).content as RootDeckWorkload;

  String opened(Outcome<String, StudyRejection> outcome) =>
      (outcome as Ok<String, StudyRejection>).value;

  CardRepositoryImpl cardRepository() => CardRepositoryImpl(
    db,
    ScheduleRepositoryImpl(db, now: () => now),
    TagRepositoryImpl(db, now: () => now),
    now: () => now,
  );

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

  test("the Resume card names the session's deck, its kind and its mode, "
      'from the session row; a session opened on a sub-deck names the '
      'sub-deck (BR-STUDY-075, BR-SRS-015, BR-MODE-008)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson A');
    await insertCard(db, id: 'n1', deckId: lesson.id, back: 'one');
    await insertCard(db, id: 'n2', deckId: lesson.id, back: 'two');
    final learning = opened(
      await entries.openLearningSession(deckId: lesson.id),
    );
    final stage = StudyMode.fromCode(
      (await sessionOf(db, learning)).read<String>('current_mode'),
    );

    expect(
      (await homeAt()).resumable,
      isA<ResumableSession>()
          .having((session) => session.sessionId, 'id', learning)
          .having((session) => session.deckName, 'deck', 'Lesson A')
          .having((session) => session.kind, 'kind', SessionKind.learning)
          .having((session) => session.mode, 'mode', stage),
    );

    await learned(lesson.id, 'd1', DateTime(2026, 9, 20));
    await lockScheduler(db, root.id);
    final review = opened(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.recall),
    );

    expect(
      (await homeAt()).resumable,
      isA<ResumableSession>()
          .having((session) => session.sessionId, 'id', review)
          .having((session) => session.deckName, 'deck', 'Korean')
          .having((session) => session.kind, 'kind', SessionKind.reviewing)
          .having((session) => session.mode, 'mode', StudyMode.recall),
    );
  });

  test('its progress is the one the session screen shows for the same '
      'session (spec D3)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    for (final id in ['a', 'b', 'c']) {
      await learned(lesson.id, id, DateTime(2026, 9, 20));
    }
    await lockScheduler(db, root.id);
    final id = opened(
      await entries.openReviewSession(
        deckId: lesson.id,
        mode: StudyMode.recall,
      ),
    );
    await answerServed(db, sessions, id, right: true);

    final progress = (await homeAt()).resumable!.progress!;
    final screen = (await StudySessionViewRepositoryImpl(
      db,
    ).watchSession(id).first)!.progress!;

    expect((progress.completed, progress.total), (1, 3));
    expect((screen.completed, screen.total), (1, 3));
  });

  test('no Resume card without an open session, nor for one that has ended, '
      'started before today, has no queue row left or belongs to an old '
      'generation (BR-STUDY-075; UC-STUDY-002 A1, A2)', () async {
    final root = await decks.root('Korean');
    final lessons = [
      for (final name in ['A', 'B', 'C']) await decks.sub(root.id, name),
    ];
    for (final (index, lesson) in lessons.indexed) {
      await insertCard(db, id: 'c$index', deckId: lesson.id, back: 'm$index');
    }
    expect((await homeAt()).resumable, isNull, reason: 'no open session');

    final first = opened(
      await entries.openLearningSession(deckId: lessons[0].id),
    );
    expect((await homeAt()).resumable?.sessionId, first);
    expect(
      (await homeAt(DateTime(2026, 9, 26, 8))).resumable,
      isNull,
      reason: 'a session of an earlier day',
    );
    await sessions.abandonSession(sessionId: first);
    expect((await homeAt()).resumable, isNull, reason: 'an ended session');

    await entries.openLearningSession(deckId: lessons[1].id);
    expect(
      await cardRepository().deleteCards(cardIds: {'c1'}),
      isA<Ok<void, CardRejection>>(),
    );
    expect((await homeAt()).resumable, isNull, reason: 'no queue row left');

    final third = opened(
      await entries.openLearningSession(deckId: lessons[2].id),
    );
    expect((await homeAt()).resumable?.sessionId, third);
    await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
      root.id,
    ]);
    await db.customStatement('UPDATE card_schedule SET generation = 2');
    expect(
      (await homeAt()).resumable,
      isNull,
      reason: 'a session from before a reset',
    );
  });

  test('of two open sessions, the newest; of two started at once, the '
      'higher id (BR-STUDY-075, spec D6)', () async {
    final root = await decks.root('Korean');
    final a = await decks.sub(root.id, 'A');
    final b = await decks.sub(root.id, 'B');
    await insertCard(db, id: 'a1', deckId: a.id, back: 'one');
    await insertCard(db, id: 'b1', deckId: b.id, back: 'two');
    final older = opened(
      await studyEntryRepository(
        db,
        () => DateTime(2026, 9, 25, 8),
      ).openLearningSession(deckId: a.id),
    );
    final newer = opened(await entries.openLearningSession(deckId: b.id));
    // Opening the second closed the first (package 2a D2): open it again.
    await db.customStatement(
      "UPDATE study_session SET status = 'in_progress', end_reason = NULL, "
      'ended_at = NULL WHERE id = ?',
      [older],
    );

    expect((await homeAt()).resumable?.sessionId, newer);

    await db.customStatement(
      'UPDATE study_session SET started_at = '
      '(SELECT started_at FROM study_session WHERE id = ?) WHERE id = ?',
      [newer, older],
    );
    expect(
      (await homeAt()).resumable?.sessionId,
      older.compareTo(newer) > 0 ? older : newer,
    );

    // One open session again, as package 2a keeps it (D2).
    await sessions.abandonSession(sessionId: older);
  });

  test(
    'of two open sessions, the newest that may be taken up: a newer one '
    'from before a reset leaves the older one offered (BR-STUDY-075)',
    () async {
      final korean = await decks.root('Korean');
      final english = await decks.root('English');
      final a = await decks.sub(korean.id, 'A');
      final b = await decks.sub(english.id, 'B');
      await insertCard(db, id: 'a1', deckId: a.id, back: 'one');
      await insertCard(db, id: 'b1', deckId: b.id, back: 'two');
      final older = opened(
        await studyEntryRepository(
          db,
          () => DateTime(2026, 9, 25, 8),
        ).openLearningSession(deckId: a.id),
      );
      await entries.openLearningSession(deckId: b.id);
      await db.customStatement(
        "UPDATE study_session SET status = 'in_progress', end_reason = NULL, "
        'ended_at = NULL WHERE id = ?',
        [older],
      );
      await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
        english.id,
      ]);
      await db.customStatement(
        "UPDATE card_schedule SET generation = 2 WHERE card_id = 'b1'",
      );

      expect((await homeAt()).resumable?.sessionId, older);

      // One open session again, as package 2a keeps it (D2).
      await sessions.abandonSession(sessionId: older);
    },
  );

  test('a session whose cards left in its round were deleted by a build '
      'before the Trash is still offered, with no progress until Continue '
      'settles it (BR-STUDY-075, spec D3)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id, back: 'one');
    await insertCard(db, id: 'c2', deckId: lesson.id, back: 'two');
    final id = opened(await entries.openLearningSession(deckId: lesson.id));
    final first = (await servedCard(db, id))!;
    await answerServed(db, sessions, id, right: true);
    await hardDeleteCards(db, {first == 'c1' ? 'c2' : 'c1'});

    final resumable = (await homeAt()).resumable;

    expect(resumable?.sessionId, id);
    expect(resumable?.progress, isNull);
  });

  test("a root deck's counts are its whole tree's: Overdue, Due today, New "
      'and its cards (BR-STUDY-076, BR-STUDY-068)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final unit = await decks.sub(lesson.id, 'Unit');
    final other = await decks.sub(korean.id, 'Other');
    final english = await decks.root('English');
    final words = await decks.sub(english.id, 'Words');
    await learned(unit.id, 'overdue', DateTime(2026, 9, 24));
    await learned(unit.id, 'today', DateTime(2026, 9, 25));
    await learned(other.id, 'later', DateTime(2026, 9, 28));
    await insertCard(db, id: 'new', deckId: other.id, back: 'new');
    await insertCard(db, id: 'english', deckId: words.id, back: 'word');
    await lockScheduler(db, korean.id);

    expect(
      [
        for (final deck in (await workload()).decks)
          (
            deck.name,
            deck.cardCount,
            deck.overdueCount,
            deck.dueTodayCount,
            deck.newCount,
          ),
      ],
      [('Korean', 4, 1, 1, 1), ('English', 1, 0, 0, 1)],
    );
  });

  test('a session whose deck is in the Trash is not offered, and a card in '
      'the Trash counts toward nothing (BR-STUDY-075, BR-STUDY-076)', () async {
    final root = await decks.root('Korean');
    final kept = await decks.sub(root.id, 'Kept');
    final trashed = await decks.sub(root.id, 'Trashed');
    await learned(kept.id, 'due', DateTime(2026, 9, 24));
    await insertCard(
      db,
      id: 'gone',
      deckId: kept.id,
      back: 'gone',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 24),
      box: 2,
      deleteBatchId: 'batch',
    );
    await insertCard(db, id: 'new', deckId: trashed.id, back: 'new');
    await lockScheduler(db, root.id);
    await entries.openLearningSession(deckId: trashed.id);
    await trashDeckRows(db, trashed.id);

    final snapshot = await homeAt();
    final deck = (snapshot.content as RootDeckWorkload).decks.single;

    expect(snapshot.resumable, isNull);
    expect((deck.cardCount, deck.overdueCount, deck.newCount), (1, 1, 0));
  });

  test('a library whose every card is in the Trash has no numbers to show '
      '(BR-STUDY-077)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'gone', deckId: lesson.id, back: 'gone');
    await trashDeckRows(db, lesson.id);

    expect((await homeAt()).content, isA<NoCards>());
  });

  test('nextDueAt is the earliest due date after now of a learned card, and '
      'null while none waits (spec D4)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'new', deckId: lesson.id, back: 'new');
    expect((await workload()).nextDueAt, isNull);

    await learned(lesson.id, 'today', DateTime(2026, 9, 25));
    await learned(lesson.id, 'later', DateTime(2026, 9, 30));
    await learned(lesson.id, 'next', DateTime(2026, 9, 27));
    await lockScheduler(db, root.id);

    expect((await workload()).nextDueAt, DateTime(2026, 9, 27));
  });

  test("reading writes nothing, even with yesterday's session open, which "
      'stays open (BR-STUDY-075, BR-STUDY-020; the backend half of IT-NAV-002 '
      'step 1)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id, back: 'one');
    final id = opened(
      await studyEntryRepository(
        db,
        () => DateTime(2026, 9, 24, 20),
      ).openLearningSession(deckId: lesson.id),
    );
    final before = await totalChanges(db);

    final snapshot = await homeAt();

    expect(snapshot.resumable, isNull);
    expect(await totalChanges(db), before);
    expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');
  });
}

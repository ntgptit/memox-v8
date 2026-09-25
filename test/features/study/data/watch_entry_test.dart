import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 1–2 and 4: the read model of the Study Entry.

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

  Future<StudyEntry> entryOf(String deckId, [DateTime? at]) async =>
      (await entries.watchEntry(deckId: deckId, now: at ?? now).first)!;

  /// A learned card of [deckId] due at [dueAt], of its own meaning.
  Future<void> learned(
    String deckId,
    String id,
    DateTime dueAt, {
    String? example,
  }) => insertCard(
    db,
    id: id,
    deckId: deckId,
    back: 'meaning $id',
    example: example,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 2,
  );

  Future<void> limitCards(int cardLimit) async => expect(
    await SettingsRepositoryImpl(db, now: () => now).saveStudyDefaults(
      options: StudyOptions(
        cardLimit: cardLimit,
        newCardOrder: NewCardOrder.created,
      ),
    ),
    isA<Ok<void, SettingsRejection>>(),
  );

  test('the entry counts the new and the due cards of the whole subtree, '
      'disjoint and never capped, and the next due date after now '
      '(IT-STUDY-001, BR-STUDY-051, BR-STUDY-008)', () async {
    final root = await decks.root('Korean');
    final lessonA = await decks.sub(root.id, 'A');
    final lessonB = await decks.sub(root.id, 'B');
    await insertCard(db, id: 'n1', deckId: lessonA.id);
    await insertCard(db, id: 'n2', deckId: lessonB.id);
    await learned(lessonA.id, 'd1', DateTime(2026, 9, 20));
    await learned(lessonB.id, 'd2', DateTime(2026, 9, 24));
    await learned(lessonA.id, 'later', DateTime(2026, 9, 27));
    await learned(lessonB.id, 'soon', DateTime(2026, 9, 25));
    await lockScheduler(db, root.id);
    await limitCards(1);

    final ofRoot = await entryOf(root.id);
    final ofA = await entryOf(lessonA.id);

    expect((ofRoot.newCardCount, ofRoot.dueCardCount), (2, 2));
    expect(ofRoot.nextDueAt, DateTime(2026, 9, 25));
    expect(
      (ofRoot.schedulerType, ofRoot.cardLimit),
      (SchedulerType.eightBox, 1),
    );
    expect((ofA.newCardCount, ofA.dueCardCount), (1, 1));
    expect(ofA.nextDueAt, DateTime(2026, 9, 27));
  });

  test('each review mode counts the cards a review would take, the first '
      'card_limit due, and says why it cannot run (BR-STUDY-044, '
      'BR-MODE-009; IT-STUDY-004, IT-STUDY-007, IT-REVIEW-010)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await learned(leaf.id, 'a', DateTime(2026, 9, 20), example: 'ex a');
    await learned(leaf.id, 'b', DateTime(2026, 9, 21));
    await learned(leaf.id, 'c', DateTime(2026, 9, 22), example: 'ex c');
    await lockScheduler(db, root.id);
    await limitCards(2);

    final options = (await entryOf(leaf.id)).reviewModes;

    expect(
      [
        for (final option in options)
          (option.mode, option.cardCount, option.unavailableReason),
      ],
      [
        (StudyMode.match, 2, null),
        (StudyMode.guess, 0, ModeUnavailableReason.tooFewMeanings),
        (StudyMode.recall, 2, null),
        (StudyMode.fill, 1, null),
      ],
    );
    expect(options.any((option) => option.isDirectionRequired), isFalse);
  });

  test('an sm2 entry offers self_assess alone, with a direction to choose '
      '(IT-STUDY-005, BR-MODE-013)', () async {
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await learned(leaf.id, 'a', DateTime(2026, 9, 20));
    await lockScheduler(db, root.id);

    final [option] = (await entryOf(leaf.id)).reviewModes;

    expect((option.mode, option.cardCount), (StudyMode.selfAssess, 1));
    expect(option.isDirectionRequired, isTrue);
  });

  test("Continue is offered for this deck's open session only while it is "
      "today's and at the root's generation (BR-STUDY-075, BR-STUDY-072; "
      'UC-STUDY-001 A3b)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id, back: 'one');
    await insertCard(db, id: 'c2', deckId: leaf.id, back: 'two');
    final opened = await entries.openLearningSession(deckId: leaf.id);
    final id = (opened as Ok<String, StudyRejection>).value;

    expect((await entryOf(leaf.id)).resumableSessionId, id);
    expect(
      (await entryOf(root.id)).resumableSessionId,
      isNull,
      reason: 'the session of another deck',
    );
    expect(
      (await entryOf(leaf.id, DateTime(2026, 9, 25, 8))).resumableSessionId,
      isNull,
      reason: 'a session of an earlier day',
    );

    await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
      root.id,
    ]);
    await db.customStatement('UPDATE card_schedule SET generation = 2');
    expect(
      (await entryOf(leaf.id)).resumableSessionId,
      isNull,
      reason: 'a session from before a reset',
    );
  });

  test('a session whose queue lost every row is not offered '
      '(BR-STUDY-075)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id);
    await entries.openLearningSession(deckId: leaf.id);
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    );

    expect(
      await cards.deleteCards(cardIds: {'c1'}),
      isA<Ok<void, CardRejection>>(),
    );

    expect((await entryOf(leaf.id)).resumableSessionId, isNull);
  });

  test('the entry emits again when the options change and when a review '
      'moves cards out of due: the due cards left outside the session '
      '(IT-REVIEW-009, spec D11)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, day) in [('a', 18), ('b', 19), ('c', 20), ('d', 21)]) {
      await learned(leaf.id, id, DateTime(2026, 9, day));
    }
    await lockScheduler(db, root.id);
    await limitCards(3);
    final limited = expectLater(
      entries.watchEntry(deckId: leaf.id, now: now),
      emitsThrough(
        isA<StudyEntry>().having((entry) => entry.cardLimit, 'limit', 2),
      ),
    );
    await limitCards(2);
    await limited;

    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    for (var turn = 0; turn < 2; turn++) {
      await answerServed(db, sessions, id, right: true);
    }

    final entry = await entryOf(leaf.id);
    expect(entry.dueCardCount, 2);
    expect(entry.resumableSessionId, isNull);
  });

  test('a deck that is gone is null (UC-STUDY-001 E1)', () async {
    expect(await entries.watchEntry(deckId: 'missing', now: now).first, isNull);
  });
}

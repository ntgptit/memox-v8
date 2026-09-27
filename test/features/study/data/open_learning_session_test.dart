import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-STUDY-001 steps 3 and 5: opening a learning session.

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
  var clock = DateTime(2026, 9, 24, 9);
  final learnedAt = DateTime(2026, 9, 10);
  setUp(() {
    clock = DateTime(2026, 9, 24, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    entries = studyEntryRepository(db, () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// [count] new cards in [deckId], `<prefix>1`…, each one minute younger
  /// than the one before and of its own meaning.
  Future<List<String>> newCards(
    String deckId,
    String prefix,
    int count, {
    bool withExample = false,
  }) async {
    final ids = [for (var i = 1; i <= count; i++) '$prefix$i'];
    for (final (index, id) in ids.indexed) {
      await insertCard(
        db,
        id: id,
        deckId: deckId,
        back: 'meaning of $id',
        example: withExample ? 'example of $id' : null,
        createdAt: DateTime(2026, 9, 1).add(Duration(minutes: index)),
      );
    }
    return ids;
  }

  /// A learned card of [deckId] and the lock its learning left on
  /// [rootId] (BR-SRS-003).
  Future<void> learnedCard(String rootId, String deckId, String id) async {
    await insertCard(
      db,
      id: id,
      deckId: deckId,
      back: 'meaning of $id',
      learnedAt: learnedAt,
      dueAt: DateTime(2026, 9, 30),
    );
    await lockScheduler(db, rootId);
  }

  test('a learning session takes the new cards of the deck and its whole '
      'subtree, and nothing else (IT-STUDY-011, BR-STUDY-051)', () async {
    final root = await decks.root('Korean');
    final lessonA = await decks.sub(root.id, 'Lesson A');
    final lessonB = await decks.sub(root.id, 'Lesson B');
    final inA = await newCards(lessonA.id, 'a', 3);
    final inB = await newCards(lessonB.id, 'b', 2);
    await learnedCard(root.id, lessonA.id, 'a-learned');

    final ofA = _opened(await entries.openLearningSession(deckId: lessonA.id));
    final ofRoot = _opened(await entries.openLearningSession(deckId: root.id));

    expect((await queueOf(db, ofA, 'browse'))..sort(), inA);
    expect((await queueOf(db, ofRoot, 'browse'))..sort(), [...inA, ...inB]);
  });

  test('the session starts in browse at the root generation, with the card '
      'limit in force (UC-STUDY-001 step 5, BR-STUDY-024)', () async {
    final root = await decks.root('Korean');
    await db.customStatement('UPDATE deck SET generation = 3 WHERE id = ?', [
      root.id,
    ]);
    final leaf = await decks.sub(root.id, 'Lesson');
    await newCards(leaf.id, 'c', 2);

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    final session = await sessionOf(db, id);
    expect(session.read<String>('deck_id'), leaf.id);
    expect(session.read<String>('root_id'), root.id);
    expect(session.read<int>('generation'), 3);
    expect(session.read<String>('session_kind'), 'learning');
    expect(session.read<String>('current_mode'), 'browse');
    expect(session.read<String>('status'), 'in_progress');
    expect(session.read<int>('cursor'), 0);
    expect(session.read<int>('card_limit'), StudyOptions.defaultCardLimit);
    expect(session.data['direction'], isNull);
    expect(session.read<DateTime>('started_at'), clock);
    final rows = await db
        .customSelect(
          'SELECT * FROM study_queue_items WHERE session_id = ? '
          "AND mode = 'browse' ORDER BY position",
          variables: [Variable(id)],
        )
        .get();
    expect([for (final row in rows) row.read<int>('position')], [0, 1]);
    for (final row in rows) {
      expect(row.read<String>('status'), 'pending');
      expect(row.read<int>('round'), 1);
      expect(row.read<int>('available_at'), 0);
      expect(row.read<int>('answers_in_session'), 0);
      expect(row.data['direction'], isNull);
    }
  });

  test('created takes the oldest cards up to the limit, and the session '
      'keeps the limit it opened with (IT-STUDY-012, IT-STUDY-010)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final cards = await newCards(leaf.id, 'limit-', 21);
    final settings = SettingsRepositoryImpl(db, now: () => clock);
    await settings.saveRootStudyOptions(
      rootDeckId: root.id,
      options: const StudyOptions(
        cardLimit: 7,
        newCardOrder: NewCardOrder.created,
      ),
    );

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));
    await settings.saveRootStudyOptions(
      rootDeckId: root.id,
      options: const StudyOptions(
        cardLimit: 3,
        newCardOrder: NewCardOrder.created,
      ),
    );

    expect((await queueOf(db, id, 'browse'))..sort(), cards.take(7).toList());
    expect((await sessionOf(db, id)).read<int>('card_limit'), 7);
  });

  test('random draws the set from the whole new set with the injected '
      'source (IT-STUDY-012, BR-STUDY-057)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final cards = await newCards(leaf.id, 'limit-', 21);
    await SettingsRepositoryImpl(db, now: () => clock).saveRootStudyOptions(
      rootDeckId: root.id,
      options: const StudyOptions(
        cardLimit: 7,
        newCardOrder: NewCardOrder.random,
      ),
    );

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    final set = await queueOf(db, id, 'browse');
    expect(set.toSet(), hasLength(7));
    expect(cards.toSet().containsAll(set), isTrue);
    expect(set.toSet(), isNot(cards.take(7).toSet()));
  });

  test('every stage of the eight_box chain asks the same cards in its own '
      'order (IT-LEARN-001, IT-LEARN-004, BR-STUDY-022)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final cards = await newCards(leaf.id, 'c', 5, withExample: true);

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    expect(await modesOf(db, id), [
      'browse',
      'match',
      'guess',
      'recall',
      'fill',
    ]);
    final orders = [
      for (final mode in ['browse', 'match', 'guess', 'recall', 'fill'])
        await queueOf(db, id, mode),
    ];
    for (final order in orders) {
      expect([...order]..sort(), cards);
    }
    for (var i = 1; i < orders.length; i++) {
      expect(orders[i], isNot(orders[i - 1]));
    }
  });

  test('the sm2 chain is browse, then self_assess (IT-LEARN-002, '
      'BR-MODE-004)', () async {
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await newCards(leaf.id, 'c', 2);

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    expect(await modesOf(db, id), ['browse', 'self_assess']);
  });

  test('a card without an example is skipped in fill only (IT-LEARN-005, '
      'BR-STUDY-071)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final plain = await newCards(leaf.id, 'p', 3);
    final withExample = await newCards(leaf.id, 'x', 2, withExample: true);

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    expect((await queueOf(db, id, 'recall'))..sort(), [
      ...plain,
      ...withExample,
    ]);
    expect((await queueOf(db, id, 'fill'))..sort(), withExample);
  });

  test('guess is skipped under five meanings, and match and guess with one '
      'card (IT-LEARN-006, IT-LEARN-007, IT-MODE-006)', () async {
    final root = await decks.root('Korean');
    final four = await decks.sub(root.id, 'Four');
    final one = await decks.sub(root.id, 'One');
    await newCards(four.id, 'f', 4);
    await newCards(one.id, 'o', 1);

    final ofFour = _opened(await entries.openLearningSession(deckId: four.id));
    final ofOne = _opened(await entries.openLearningSession(deckId: one.id));

    expect(await modesOf(db, ofFour), ['browse', 'match', 'recall']);
    expect(await modesOf(db, ofOne), ['browse', 'recall']);
  });

  test("guess counts the meanings of the tree's learned cards, never of "
      'another tree (spec D5, IT-MODE-015)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    final learned = await decks.sub(root.id, 'Learned');
    await newCards(lesson.id, 'n', 1);
    for (final id in ['l1', 'l2', 'l3']) {
      await learnedCard(root.id, learned.id, id);
    }
    final other = await decks.root('Other');
    final otherLeaf = await decks.sub(other.id, 'Leaf');
    for (final id in ['o1', 'o2', 'o3', 'o4', 'o5']) {
      await learnedCard(other.id, otherLeaf.id, id);
    }

    final withThree = _opened(
      await entries.openLearningSession(deckId: lesson.id),
    );
    await learnedCard(root.id, learned.id, 'l4');
    final withFour = _opened(
      await entries.openLearningSession(deckId: lesson.id),
    );

    expect(await modesOf(db, withThree), isNot(contains('guess')));
    expect(await queueOf(db, withFour, 'guess'), ['n1']);
  });

  test('opening closes the open session of the app: user_exit the same day, '
      'interrupted from an earlier day (BR-STUDY-072, spec D2; '
      'IT-CONT-002)', () async {
    final root = await decks.root('Korean');
    final lessonA = await decks.sub(root.id, 'Lesson A');
    final other = await decks.root('Other');
    final lessonB = await decks.sub(other.id, 'Lesson B');
    await newCards(lessonA.id, 'a', 2);
    await newCards(lessonB.id, 'b', 2);

    final first = _opened(
      await entries.openLearningSession(deckId: lessonA.id),
    );
    clock = DateTime(2026, 9, 24, 21);
    final second = _opened(
      await entries.openLearningSession(deckId: lessonB.id),
    );
    clock = DateTime(2026, 9, 25, 7);
    final third = _opened(
      await entries.openLearningSession(deckId: lessonA.id),
    );

    final closedSameDay = await sessionOf(db, first);
    expect(closedSameDay.read<String>('status'), 'abandoned');
    expect(closedSameDay.read<String>('end_reason'), 'user_exit');
    expect(closedSameDay.read<DateTime>('ended_at'), DateTime(2026, 9, 24, 21));
    final closedNextDay = await sessionOf(db, second);
    expect(closedNextDay.read<String>('end_reason'), 'interrupted');
    expect(closedNextDay.read<DateTime>('ended_at'), clock);
    expect((await sessionOf(db, third)).read<String>('status'), 'in_progress');
  });

  test('a deck with nothing new is refused, writing nothing and leaving the '
      'open session open (BR-STUDY-020)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final done = await decks.sub(root.id, 'Done');
    await newCards(leaf.id, 'c', 1);
    await learnedCard(root.id, done.id, 'l1');
    final open = _opened(await entries.openLearningSession(deckId: leaf.id));
    final before = await totalChanges(db);

    expect(
      await entries.openLearningSession(deckId: done.id),
      _refusedWith(StudyRejection.nothingToLearn),
    );
    expect(await totalChanges(db), before);
    expect((await sessionOf(db, open)).read<String>('status'), 'in_progress');
  });

  test('a missing deck and a deck in the Trash are notFound', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await newCards(leaf.id, 'c', 1);
    await trashDeckRows(db, leaf.id);

    expect(
      await entries.openLearningSession(deckId: 'missing'),
      _refusedWith(StudyRejection.notFound),
    );
    expect(
      await entries.openLearningSession(deckId: leaf.id),
      _refusedWith(StudyRejection.notFound),
    );
  });
}

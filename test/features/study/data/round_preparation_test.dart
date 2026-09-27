import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
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
import '../../../support/trash_fixtures.dart';

// Graded modes spec §8.2: a round gets what it needs when it starts being
// served, the options of its guess questions and the meaning slots of its
// match boards, and keeps them.

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudySessionViewRepositoryImpl views;
  final now = DateTime(2026, 9, 24, 9);

  void open(AppDatabase database) {
    db = database;
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    views = StudySessionViewRepositoryImpl(db);
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudySessionView> viewOf(String sessionId) async =>
      (await views.watchSession(sessionId).first)!;

  Future<(DeckEntity, DeckEntity)> tree([String name = 'Korean']) async {
    final root = await decks.root(name);
    return (root, await decks.sub(root.id, 'Lesson'));
  }

  /// A learned card of [deckId], due now when [due], of the meaning [back].
  Future<void> learned(
    DeckEntity root,
    String deckId,
    String id, {
    required String back,
    bool due = false,
  }) async {
    await insertCard(
      db,
      id: id,
      deckId: deckId,
      back: back,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: due ? DateTime(2026, 9, 20) : DateTime(2026, 10, 20),
    );
    await lockScheduler(db, root.id);
  }

  Future<String> review(String deckId, StudyMode mode) async =>
      ((await entries.openReviewSession(
        deckId: deckId,
        mode: mode,
      )) as Ok<String, StudyRejection>).value;

  /// Five due cards of five meanings under a fresh tree.
  Future<DeckEntity> fiveDue() async {
    final (root, leaf) = await tree();
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
      'library',
    ].indexed) {
      await learned(root, leaf.id, 'c$index', back: meaning, due: true);
    }
    return leaf;
  }

  test('the options come from the learned cards of the same tree: no new card '
      'outside the session, no card of another root, one card per meaning '
      '(BR-STUDY-037 to BR-STUDY-039; IT-MODE-015)', () async {
    final (root, leaf) = await tree('A');
    await learned(root, leaf.id, 'asked', back: 'library', due: true);
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
    ].indexed) {
      await learned(root, leaf.id, 'd$index', back: meaning);
    }
    await learned(root, leaf.id, 'variant', back: '  KITCHEN ');
    await insertCard(db, id: 'new', deckId: leaf.id, back: 'new-only-secret');
    final (other, otherLeaf) = await tree('B');
    await learned(other, otherLeaf.id, 'other', back: 'other-root-secret');

    final id = await review(leaf.id, StudyMode.guess);
    final question = (await viewOf(id)).currentItem!.guess!;

    expect(question.isBlocked, isFalse);
    final meanings = [
      for (final option in question.options)
        option.meaning.trim().toLowerCase(),
    ];
    expect(meanings.toSet(), {
      'library',
      'kitchen',
      'school',
      'office',
      'garden',
    });
    expect([
      for (final option in question.options) option.cardId,
    ], containsOnce('asked'));
  });

  test('the options and the card order stay as they are across Continue, and '
      'a new round has its own order and its own questions (BR-STUDY-043, '
      'BR-STUDY-061; IT-MODE-007)', () async {
    final leaf = await fiveDue();
    final id = await review(leaf.id, StudyMode.guess);
    final order = await queueOf(db, id, 'guess');
    final questions = {
      for (final card in order) card: await optionsOf(db, id, card),
    };
    for (final options in questions.values) {
      expect(options, hasLength(5));
    }

    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );
    expect(await queueOf(db, id, 'guess'), order);
    for (final card in order) {
      expect(await optionsOf(db, id, card), questions[card], reason: card);
    }

    await answerServed(db, sessions, id, right: false);
    await answerServed(db, sessions, id, right: false);
    for (var turn = 0; turn < 3; turn++) {
      await answerServed(db, sessions, id, right: true);
    }
    final second = await queueOf(db, id, 'guess', round: 2);
    expect(second.toSet(), {order[0], order[1]});
    expect(second, isNot([order[0], order[1]]));
    for (final card in second) {
      expect(await optionsOf(db, id, card, round: 2), hasLength(5));
    }
  });

  test('a learning session prepares its guess questions when the stage '
      'starts, not when it opens (spec D8)', () async {
    final (_, leaf) = await tree();
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
      'library',
    ].indexed) {
      await insertCard(db, id: 'n$index', deckId: leaf.id, back: meaning);
    }
    final id = ((await entries.openLearningSession(
      deckId: leaf.id,
    )) as Ok<String, StudyRejection>).value;
    final guessed = await queueOf(db, id, 'guess');
    expect(await optionsOf(db, id, guessed.first), isEmpty);

    while ((await sessionOf(db, id)).read<String>('current_mode') != 'guess') {
      await answerServed(db, sessions, id, right: true);
    }
    for (final card in guessed) {
      expect(await optionsOf(db, id, card), hasLength(5), reason: card);
    }
  });

  test('a review opened in match gives every board its meaning slots, never '
      "in its terms' order, and the view shows the board (BR-STUDY-049; "
      'spec D7)', () async {
    final (root, leaf) = await tree();
    for (var index = 0; index < 7; index++) {
      await learned(
        root,
        leaf.id,
        'c$index',
        back: 'meaning $index',
        due: true,
      );
    }
    final id = await review(leaf.id, StudyMode.match);
    final order = await queueOf(db, id, 'match');
    final slots = await meaningSlotsOf(db, id);

    final first = [for (final card in order.take(5)) slots[card]];
    expect(first.toSet(), {0, 1, 2, 3, 4});
    expect(first, isNot([0, 1, 2, 3, 4]));
    expect([for (final card in order.skip(5)) slots[card]], [1, 0]);

    final board = (await viewOf(id)).board!;
    expect([for (final tile in board.terms) tile.cardId], order.take(5));
    expect(
      [for (final tile in board.meanings) slots[tile.cardId]],
      [0, 1, 2, 3, 4],
    );
    expect(board.terms.every((tile) => !tile.isMatched), isTrue);
  });

  test('the board keeps its tiles in place and marks the pairs matched in the '
      'round (BR-STUDY-049; the backend half of IT-MODE-003)', () async {
    final (root, leaf) = await tree();
    for (var index = 0; index < 3; index++) {
      await learned(
        root,
        leaf.id,
        'c$index',
        back: 'meaning $index',
        due: true,
      );
    }
    final id = await review(leaf.id, StudyMode.match);
    final before = (await viewOf(id)).board!;
    final matched = before.terms.first.cardId;

    await answerServed(db, sessions, id, right: true, cardId: matched);

    final after = (await viewOf(id)).board!;
    expect(
      [for (final tile in after.terms) tile.cardId],
      [for (final tile in before.terms) tile.cardId],
    );
    expect(
      [for (final tile in after.meanings) tile.cardId],
      [for (final tile in before.meanings) tile.cardId],
    );
    expect(
      {
        for (final tile in [...after.terms, ...after.meanings])
          if (tile.isMatched) tile.cardId,
      },
      {matched},
    );
  });

  test('Continue fills in what a round lacks, as a session from before v2 '
      'has: the questions of guess and the slots of match (spec §6.5, '
      '§8.2)', () async {
    final leaf = await fiveDue();
    final guessId = await review(leaf.id, StudyMode.guess);
    await db.customStatement('DELETE FROM study_guess_options');
    expect((await viewOf(guessId)).currentItem!.guess!.isBlocked, isTrue);

    await sessions.resumeSession(sessionId: guessId);
    for (final card in await queueOf(db, guessId, 'guess')) {
      expect(await optionsOf(db, guessId, card), hasLength(5), reason: card);
    }

    final matchId = await review(leaf.id, StudyMode.match);
    await db.customStatement(
      'UPDATE study_queue_items SET meaning_slot = NULL',
    );
    await sessions.resumeSession(sessionId: matchId);
    expect((await meaningSlotsOf(db, matchId)).values.toSet(), {0, 1, 2, 3, 4});
  });

  test('a question that lost an option to a deleted card is blocked until '
      'Continue builds it again from what is left (BR-STUDY-040; spec '
      '§8.2)', () async {
    final (root, leaf) = await tree();
    await learned(root, leaf.id, 'asked', back: 'library', due: true);
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
      'river',
    ].indexed) {
      await learned(root, leaf.id, 'd$index', back: meaning);
    }
    final id = await review(leaf.id, StudyMode.guess);
    final gone = (await optionsOf(
      db,
      id,
      'asked',
    )).firstWhere((card) => card != 'asked');
    await db.customStatement("DELETE FROM card WHERE id = '$gone'");

    expect(await optionsOf(db, id, 'asked'), hasLength(4));
    final blocked = (await viewOf(id)).currentItem!.guess!;
    expect(blocked.isBlocked, isTrue);
    expect(blocked.options, isEmpty);

    await sessions.resumeSession(sessionId: id);
    final rebuilt = await optionsOf(db, id, 'asked');
    expect(rebuilt, hasLength(5));
    expect(rebuilt, isNot(contains(gone)));
  });

  test('an option that went to the Trash is never shown: the question is '
      'blocked, as for a deleted card (BR-TRASH-002, BR-STUDY-040)', () async {
    final (root, leaf) = await tree();
    await learned(root, leaf.id, 'asked', back: 'library', due: true);
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
      'river',
    ].indexed) {
      await learned(root, leaf.id, 'd$index', back: meaning);
    }
    final id = await review(leaf.id, StudyMode.guess);
    final trashed = (await optionsOf(
      db,
      id,
      'asked',
    )).firstWhere((card) => card != 'asked');
    await trashCardRow(db, trashed);

    final question = (await viewOf(id)).currentItem!.guess!;
    expect(question.isBlocked, isTrue);
    expect(question.options, isEmpty);
  });

  test('a question its meaning source cannot fill stores no option, and the '
      'view shows it blocked (BR-STUDY-040)', () async {
    await db.close();
    open(openTestDatabase(interceptor: ThinMeaningSource(4)));
    final leaf = await fiveDue();
    final id = await review(leaf.id, StudyMode.guess);

    final served = await servedCard(db, id);
    expect(await optionsOf(db, id, served!), isEmpty);
    final question = (await viewOf(id)).currentItem!.guess!;
    expect(question.isBlocked, isTrue);
  });
}

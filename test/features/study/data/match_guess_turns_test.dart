import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 6–9 in `match` and `guess`: a turn judges the pair or
// the option the person picked (graded modes spec §7.5, §7.6, §8.1).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);

  void open(AppDatabase database) {
    db = database;
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<Outcome<TurnResult, StudyRejection>> turn(
    String sessionId,
    String cardId,
    StudyAnswer answer,
  ) =>
      sessions.answerTurn(sessionId: sessionId, cardId: cardId, answer: answer);

  /// A match review of seven learned, due cards `c0`…`c6` of seven meanings:
  /// two boards, of five pairs and of two.
  Future<String> sevenPairs() async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (var index = 0; index < 7; index++) {
      await insertCard(
        db,
        id: 'c$index',
        deckId: leaf.id,
        back: 'meaning $index',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 10 + index),
      );
    }
    await lockScheduler(db, root.id);
    return openReview(entries, leaf.id, StudyMode.match);
  }

  test(
    'a wrong pair is a wrong turn of the term card only; the pair stays on '
    'the board, and the next round holds exactly the cards that were ever '
    'wrong (BR-STUDY-060, BR-STUDY-062, BR-STUDY-070; IT-MODE-004F)',
    () async {
      final leaf = await insertFiveDue(db, decks);
      final id = await openReview(entries, leaf.id, StudyMode.match);

      expect(
        await turn(id, 'ST-01', const MatchAnswer('ST-02')),
        judged(isCorrect: false),
      );
      expect(await reviewLogsOf(db, 'ST-02'), isEmpty);
      expect(
        (await reviewLogsOf(db, 'ST-01')).single.read<String>('action'),
        'forgotten',
      );
      expect([
        for (final tile in (await watchSessionOnce(db, id)).board!.terms)
          tile.isMatched,
      ], everyElement(isFalse));

      expect(
        await turn(id, 'ST-01', const MatchAnswer('ST-01')),
        judged(isCorrect: true),
      );
      await turn(id, 'ST-03', const MatchAnswer('ST-04'));
      await turn(id, 'ST-03', const MatchAnswer('ST-03'));
      for (final card in ['ST-02', 'ST-04', 'ST-05']) {
        expect(
          await turn(id, card, MatchAnswer(card)),
          judged(isCorrect: true),
        );
      }

      expect((await queueOf(db, id, 'match', round: 2)).toSet(), {
        'ST-01',
        'ST-03',
      });
      final logs = await reviewLogsOf(db, 'ST-01');
      expect(logs.every((log) => log.data['outcome_reason'] == null), isTrue);
      expect(
        logs.every((log) => log.data['comparison_version'] == null),
        isTrue,
      );
    },
  );

  test('a right pair on another card of the same meaning takes that tile, so '
      'the tile tapped is the one matched (spec D3, §7.6)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, meaning, day) in [
      ('a', 'water', 10),
      ('b', ' Water', 11),
      ('c', 'fire', 12),
    ]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        back: meaning,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
      );
    }
    await lockScheduler(db, root.id);
    final id = await openReview(entries, leaf.id, StudyMode.match);
    final slots = await meaningSlotsOf(db, id);
    final meanings = (await watchSessionOnce(db, id)).board!.meanings;
    final tapped = meanings.indexWhere((tile) => tile.cardId == 'b');
    final other = meanings.indexWhere((tile) => tile.cardId == 'a');

    expect(
      await turn(id, 'a', const MatchAnswer('b')),
      judged(isCorrect: true),
    );

    final swapped = await meaningSlotsOf(db, id);
    expect((swapped['a'], swapped['b']), (slots['b'], slots['a']));
    final after = (await watchSessionOnce(db, id)).board!.meanings;
    expect((after[tapped].cardId, after[tapped].isMatched), ('a', true));
    expect((after[other].cardId, after[other].isMatched), ('b', false));
    expect(
      await turn(id, 'b', const MatchAnswer('b')),
      judged(isCorrect: true),
    );
  });

  test('a turn stays on the current board: a meaning of another board is '
      'refused, and so is a term there (BR-STUDY-049)', () async {
    final id = await sevenPairs();
    final order = await queueOf(db, id, 'match');
    final before = await totalChanges(db);

    expect(
      await turn(id, order.first, MatchAnswer(order.last)),
      refusedWith<TurnResult>(StudyRejection.notOnBoard),
    );
    expect(
      await turn(id, order.last, MatchAnswer(order.last)),
      refusedWith<TurnResult>(StudyRejection.notCurrentCard),
    );
    expect(await totalChanges(db), before);
  });

  test('once every pair of a board is matched, the next board is the current '
      'one, and its pairs end the round (BR-STUDY-049)', () async {
    final id = await sevenPairs();
    final order = await queueOf(db, id, 'match');
    for (final card in order.take(5)) {
      expect(await turn(id, card, MatchAnswer(card)), judged(isCorrect: true));
    }

    final board = (await watchSessionOnce(db, id)).board!;
    expect([for (final tile in board.terms) tile.cardId], order.skip(5));
    for (final card in order.skip(5)) {
      expect(await turn(id, card, MatchAnswer(card)), judged(isCorrect: true));
    }
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
  });

  test('a meaning already matched is off the board: refused, with nothing '
      'written (BR-STUDY-049)', () async {
    final leaf = await insertFiveDue(db, decks);
    final id = await openReview(entries, leaf.id, StudyMode.match);
    await turn(id, 'ST-01', const MatchAnswer('ST-01'));
    final before = await totalChanges(db);

    expect(
      await turn(id, 'ST-02', const MatchAnswer('ST-01')),
      refusedWith<TurnResult>(StudyRejection.notOnBoard),
    );
    expect(await totalChanges(db), before);
  });

  test(
    'a card deleted while its pair is on the board takes its pair away: '
    'the other pairs keep their tiles, and the round ends without it',
    () async {
      final leaf = await insertFiveDue(db, decks);
      final id = await openReview(entries, leaf.id, StudyMode.match);
      final before = (await watchSessionOnce(db, id)).board!;
      await db.customStatement("DELETE FROM card WHERE id = 'ST-03'");

      final after = (await watchSessionOnce(db, id)).board!;
      List<String> kept(List<MatchTile> tiles) => [
        for (final tile in tiles)
          if (tile.cardId != 'ST-03') tile.cardId,
      ];
      expect([for (final tile in after.terms) tile.cardId], kept(before.terms));
      expect([
        for (final tile in after.meanings) tile.cardId,
      ], kept(before.meanings));
      for (final card in ['ST-01', 'ST-02', 'ST-04', 'ST-05']) {
        expect(
          await turn(id, card, MatchAnswer(card)),
          judged(isCorrect: true),
        );
      }
      expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    },
  );

  test('a guess question has five options, the right one once; the first '
      'pick is the one turn it records (BR-STUDY-037, BR-STUDY-041, '
      'BR-STUDY-042; IT-MODE-005F)', () async {
    final leaf = await insertFiveDue(db, decks);
    final id = await openReview(entries, leaf.id, StudyMode.guess);
    final options = (await watchSessionOnce(
      db,
      id,
    )).currentItem!.guess!.options;
    expect(options, hasLength(5));
    expect([
      for (final option in options) option.cardId,
    ], containsOnce('ST-01'));
    final wrong = options.firstWhere((option) => option.cardId != 'ST-01');

    expect(
      await turn(id, 'ST-01', GuessAnswer(wrong.cardId)),
      judged(isCorrect: false),
    );
    expect(
      await turn(id, 'ST-01', const GuessAnswer('ST-01')),
      refusedWith<TurnResult>(StudyRejection.notCurrentCard),
    );
    expect(await reviewLogCount(db), 1);
    expect(
      (await reviewLogsOf(db, 'ST-01')).single.read<String>('action'),
      'forgotten',
    );
  });

  test('a card that is not one of the options is refused and writes nothing '
      '(BR-STUDY-041)', () async {
    final leaf = await insertFiveDue(db, decks);
    final id = await openReview(entries, leaf.id, StudyMode.guess);
    final before = await totalChanges(db);

    expect(
      await turn(id, 'ST-01', const GuessAnswer('elsewhere')),
      refusedWith<TurnResult>(StudyRejection.notAnOption),
    );
    expect(await totalChanges(db), before);
  });

  test('an answer on a question that lost an option to a deleted card is '
      'refused as blocked, with nothing written; Continue builds the question '
      'again from what is left (BR-STUDY-040)', () async {
    final leaf = await insertFiveDue(db, decks);
    await insertCard(
      db,
      id: 'ST-06',
      deckId: leaf.id,
      back: 'fig',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 10, 20),
    );
    final id = await openReview(entries, leaf.id, StudyMode.guess);
    final gone = (await optionsOf(
      db,
      id,
      'ST-01',
    )).firstWhere((card) => card != 'ST-01');
    await db.customStatement("DELETE FROM card WHERE id = '$gone'");
    final before = await totalChanges(db);

    expect(
      await turn(id, 'ST-01', const GuessAnswer('ST-01')),
      refusedWith<TurnResult>(StudyRejection.questionBlocked),
    );
    expect(await totalChanges(db), before);

    await sessions.resumeSession(sessionId: id);
    expect(await optionsOf(db, id, 'ST-01'), hasLength(5));
    expect(
      await turn(id, 'ST-01', const GuessAnswer('ST-01')),
      judged(isCorrect: true),
    );
  });

  test('a blocked question stores no option, takes no answer and moves '
      'nothing; once the person leaves, a new session without the fault '
      'builds five options '
      '(BR-STUDY-040; IT-MODE-014)', () async {
    await db.close();
    final fault = ThinMeaningSource(4);
    open(openTestDatabase(interceptor: fault));
    final leaf = await insertFiveDue(db, decks);
    final id = await openReview(entries, leaf.id, StudyMode.guess);
    final view = await watchSessionOnce(db, id);
    expect(view.currentItem!.cardId, 'ST-01');
    expect(view.currentItem!.guess!.isBlocked, isTrue);
    expect(await optionsOf(db, id, 'ST-01'), isEmpty);
    final before = await totalChanges(db);

    expect(
      await turn(id, 'ST-01', const GuessAnswer('ST-01')),
      refusedWith<TurnResult>(StudyRejection.questionBlocked),
    );
    expect(await totalChanges(db), before);
    final still = await watchSessionOnce(db, id);
    expect(still.currentItem!.cardId, 'ST-01');
    expect(still.progress!.completed, 0);

    expect(
      await sessions.abandonSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );
    fault.keep = null;
    final again = await openReview(entries, leaf.id, StudyMode.guess);
    expect(
      (await watchSessionOnce(db, again)).currentItem!.guess!.options,
      hasLength(5),
    );
    expect(
      await turn(again, 'ST-01', const GuessAnswer('ST-01')),
      judged(isCorrect: true),
    );
  });
}

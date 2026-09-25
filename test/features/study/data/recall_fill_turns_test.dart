import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 6–9 in `recall` and `fill`: a turn judges the person's
// self-assessment or the term typed (graded modes spec §7.3, §7.4, §8.1).

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<TurnResult, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

Matcher _judged({required bool isCorrect}) =>
    isA<Ok<TurnResult, StudyRejection>>().having(
      (ok) => ok.value.isCorrect,
      'isCorrect',
      isCorrect,
    );

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

  Future<String> review(String deckId, StudyMode mode) async =>
      ((await entries.openReviewSession(
        deckId: deckId,
        mode: mode,
      )) as Ok<String, StudyRejection>).value;

  Future<Outcome<TurnResult, StudyRejection>> turn(
    String sessionId,
    String cardId,
    StudyAnswer answer,
  ) =>
      sessions.answerTurn(sessionId: sessionId, cardId: cardId, answer: answer);

  Future<List<QueryRow>> logsOf(String cardId) => db
      .customSelect(
        'SELECT * FROM review_log WHERE card_id = ? ORDER BY rowid',
        variables: [Variable<String>(cardId)],
      )
      .get();

  Future<int> turnCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  test(
    'revealing records nothing; the self-assessment after it is the one '
    'turn, and is refused before a reveal (BR-STUDY-065; IT-MODE-008F)',
    () async {
      final leaf = await insertFiveDue(db, decks);
      final id = await review(leaf.id, StudyMode.recall);

      expect(
        await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.remembered)),
        _refusedWith(StudyRejection.notRevealed),
      );
      await sessions.revealRecallAnswer(
        sessionId: id,
        cardId: 'ST-01',
        remainingMs: 12000,
      );
      expect(await turnCount(), 0);

      expect(
        await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.remembered)),
        _judged(isCorrect: true),
      );
      expect(
        await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.forgot)),
        _refusedWith(StudyRejection.notCurrentCard),
      );
      final log = (await logsOf('ST-01')).single;
      expect(log.read<String>('action'), 'remembered');
      expect(log.data['outcome_reason'], isNull);
    },
  );

  test('the time left survives Continue; a timeout records wrong with its '
      'reason, and nothing after it or after a reveal takes a second '
      'outcome (BR-STUDY-032 to BR-STUDY-036; IT-MODE-009F)', () async {
    final leaf = await insertFiveDue(db, decks);
    final id = await review(leaf.id, StudyMode.recall);
    await sessions.saveRecallTime(
      sessionId: id,
      cardId: 'ST-01',
      remainingMs: 12400,
    );
    await sessions.resumeSession(sessionId: id);
    final resumed = (await viewOf(id)).currentItem!;
    expect((resumed.remainingMs, resumed.isRevealed), (12400, false));

    expect(
      await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.timedOut)),
      _judged(isCorrect: false),
    );
    final log = (await logsOf('ST-01')).single;
    expect(log.read<String>('action'), 'forgotten');
    expect(log.read<String>('outcome_reason'), 'timeout');
    expect(
      await sessions.revealRecallAnswer(
        sessionId: id,
        cardId: 'ST-01',
        remainingMs: 0,
      ),
      isA<Rejected<void, StudyRejection>>(),
    );
    expect(
      await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.timedOut)),
      _refusedWith(StudyRejection.notCurrentCard),
    );

    await sessions.revealRecallAnswer(
      sessionId: id,
      cardId: 'ST-02',
      remainingMs: 3000,
    );
    expect(
      await turn(id, 'ST-02', const RecallAnswer(RecallOutcome.timedOut)),
      _refusedWith(StudyRejection.alreadyRevealed),
    );
    expect(await logsOf('ST-02'), isEmpty);
  });

  group('fill on S-STUDY-FILL-V2: front `Công`, back `Nghề nghiệp`', () {
    /// A fresh tree holding the one card of S-STUDY-FILL-V2, and a fill review
    /// on it.
    Future<String> fillReview(String rootName) async {
      final root = await decks.root(rootName);
      final leaf = await decks.sub(root.id, 'Lesson');
      await insertCard(
        db,
        id: '$rootName-card',
        deckId: leaf.id,
        front: 'Công',
        back: 'Nghề nghiệp',
        example: 'Đây là một công việc tốt.',
        hint: 'Bắt đầu bằng C',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 20),
      );
      await lockScheduler(db, root.id);
      return review(leaf.id, StudyMode.fill);
    }

    test('spaces and case fall away and accents stay; a blank answer writes '
        'nothing, and what was typed is kept nowhere (BR-STUDY-026, '
        'BR-STUDY-027, BR-STUDY-029, BR-STUDY-030; IT-MODE-010)', () async {
      final blank = await fillReview('A');
      final before = await totalChanges(db);
      for (final typed in ['', '   ']) {
        expect(
          await turn(blank, 'A-card', FillAnswer(typed)),
          _refusedWith(StudyRejection.emptyAnswer),
        );
      }
      expect(await totalChanges(db), before);
      expect((await sessionOf(db, blank)).read<int>('cursor'), 0);

      final cased = await fillReview('B');
      expect(
        await turn(cased, 'B-card', const FillAnswer('  cÔnG  ')),
        _judged(isCorrect: true),
      );

      final unaccented = await fillReview('C');
      expect(
        await turn(unaccented, 'C-card', const FillAnswer('cong')),
        _judged(isCorrect: false),
      );
      final log = (await logsOf('C-card')).single;
      expect(log.read<String>('action'), 'forgotten');
      expect(log.read<int>('comparison_version'), 1);
      expect(log.read<bool>('used_hint'), isFalse);
      final stored = [
        for (final row
            in await db.customSelect('SELECT * FROM review_log').get())
          ...row.data.values,
        for (final row
            in await db.customSelect('SELECT * FROM study_queue_items').get())
          ...row.data.values,
      ];
      expect(stored, isNot(contains('cong')));
      expect(stored, isNot(contains('  cÔnG  ')));
    });

    test('a shown hint is recorded on a turn it does not turn right; the one '
        'submission ends the turn, and the card comes back as a new turn of '
        'the next round (BR-STUDY-028, BR-STUDY-059; IT-MODE-011)', () async {
      final id = await fillReview('A');
      await sessions.showFillHint(sessionId: id, cardId: 'A-card');

      expect(
        await turn(id, 'A-card', const FillAnswer('Cong')),
        _judged(isCorrect: false),
      );
      final log = (await logsOf('A-card')).single;
      expect(log.read<String>('action'), 'forgotten');
      expect(log.read<bool>('used_hint'), isTrue);
      final rows = await db
          .customSelect(
            'SELECT round, status, hint_shown FROM study_queue_items'
            ' WHERE session_id = ? ORDER BY round',
            variables: [Variable<String>(id)],
          )
          .get();
      expect(
        [
          for (final row in rows)
            (
              row.read<int>('round'),
              row.read<String>('status'),
              row.read<int>('hint_shown'),
            ),
        ],
        [(1, 'completed', 1), (2, 'pending', 0)],
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 E3 in the repository: the write the use case makes once a
// turn failed for good.

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

  /// A learning session on one new card [cardId] of a fresh sm2 tree [name].
  Future<String> learningOn(String name, String cardId) async {
    final root = await decks.root(name, SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: cardId, deckId: leaf.id);
    final opened = await entries.openLearningSession(deckId: leaf.id);
    return (opened as Ok<String, StudyRejection>).value;
  }

  Future<void> answer(String sessionId, StudyAnswer answer) async => expect(
    await sessions.answerTurn(
      sessionId: sessionId,
      cardId: (await servedCard(db, sessionId))!,
      answer: answer,
    ),
    isA<Ok<void, StudyRejection>>(),
  );

  test('failSession closes an open session as failed/persistence_error and '
      'keeps its turns (BR-STUDY-018, BR-STUDY-019)', () async {
    final id = await learningOn('Korean', 'c1');
    await answer(id, const AdvanceAnswer());
    await answer(id, const SelfAssessAnswer(Sm2Action.again));
    final later = now.add(const Duration(minutes: 5));

    await sessions.failSession(sessionId: id, now: later);

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'failed');
    expect(session.read<String>('end_reason'), 'persistence_error');
    expect(session.read<DateTime>('ended_at'), later);
    expect(await turnKindsOf(db, 'c1'), ['learning']);
  });

  test('failSession leaves a session that has ended, or is gone, as it is '
      '(spec §7.5)', () async {
    final first = await learningOn('Korean', 'c1');
    await learningOn('Japanese', 'c2');

    await sessions.failSession(sessionId: first);
    await sessions.failSession(sessionId: 'missing');

    final session = await sessionOf(db, first);
    expect(session.read<String>('status'), 'abandoned');
    expect(session.read<String>('end_reason'), 'user_exit');
  });
}

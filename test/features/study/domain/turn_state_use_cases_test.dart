import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/usecases/reveal_recall_answer_use_case.dart';
import 'package:memox/features/study/domain/usecases/save_recall_time_use_case.dart';
import 'package:memox/features/study/domain/usecases/show_fill_hint_use_case.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// The three writes of graded modes spec §8.3 through the use cases the
// recall and fill screens call.

void main() {
  late AppDatabase db;
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() => db.close());

  Future<String> opened(StudyMode mode) async {
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      example: 'example',
      hint: 'hint',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
    await lockScheduler(db, root.id);
    final result = await studyEntryRepository(
      db,
      () => now,
    ).openReviewSession(deckId: leaf.id, mode: mode);
    return (result as Ok<String, StudyRejection>).value;
  }

  test('RevealRecallAnswer and SaveRecallTime take the time left of the '
      'turn', () async {
    final id = await opened(StudyMode.recall);

    expect(
      await SaveRecallTimeUseCase(sessions)(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 14000,
      ),
      isA<Ok<void, StudyRejection>>(),
    );
    expect(
      await RevealRecallAnswerUseCase(sessions)(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 13000,
      ),
      isA<Ok<void, StudyRejection>>(),
    );
  });

  test('a time outside 0 to 20 seconds is a bug in the caller: nothing is '
      'written', () async {
    final id = await opened(StudyMode.recall);
    final before = await totalChanges(db);

    for (final remainingMs in [-1, 20001]) {
      expect(
        () => SaveRecallTimeUseCase(sessions)(
          sessionId: id,
          cardId: 'c1',
          remainingMs: remainingMs,
        ),
        throwsArgumentError,
      );
      expect(
        () => RevealRecallAnswerUseCase(sessions)(
          sessionId: id,
          cardId: 'c1',
          remainingMs: remainingMs,
        ),
        throwsArgumentError,
      );
    }
    expect(await totalChanges(db), before);
  });

  test('ShowFillHint shows the hint of the turn', () async {
    final id = await opened(StudyMode.fill);

    expect(
      await ShowFillHintUseCase(sessions)(sessionId: id, cardId: 'c1'),
      isA<Ok<void, StudyRejection>>(),
    );
  });
}

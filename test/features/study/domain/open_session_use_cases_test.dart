import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/usecases/open_learning_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/open_review_session_use_case.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 3–5 through the use cases the Study Entry calls.

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('OpenLearningSession opens a session on the deck and answers its id '
      '(UC-STUDY-001 step 3)', () async {
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id);
    final open = OpenLearningSessionUseCase(
      studyEntryRepository(db, () => now),
    );

    final result = await open(deckId: leaf.id);

    final id = (result as Ok<String, StudyRejection>).value;
    expect((await sessionOf(db, id)).read<String>('deck_id'), leaf.id);
    expect(
      await open(deckId: 'missing'),
      isA<Rejected<String, StudyRejection>>(),
    );
  });

  test('OpenReviewSession opens a review in the mode picked, with the '
      'direction chosen (UC-STUDY-001 step 4, UC-STUDY-003 step 5)', () async {
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
    await lockScheduler(db, root.id);
    final open = OpenReviewSessionUseCase(studyEntryRepository(db, () => now));

    final result = await open(
      deckId: leaf.id,
      mode: StudyMode.selfAssess,
      direction: DirectionChoice.koreanToMeaning,
    );

    final id = (result as Ok<String, StudyRejection>).value;
    final session = await sessionOf(db, id);
    expect(session.read<String>('session_kind'), 'reviewing');
    expect(session.read<String>('direction'), 'korean_to_meaning');
  });
}

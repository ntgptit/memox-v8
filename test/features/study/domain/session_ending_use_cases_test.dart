import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/usecases/abandon_stale_sessions_use_case.dart';
import 'package:memox/features/study/domain/usecases/abandon_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/resume_study_session_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 A3 and A3b through the use cases the session screen and the
// app start call.

void main() {
  late AppDatabase db;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  var clock = DateTime(2026, 9, 24, 9);
  setUp(() {
    clock = DateTime(2026, 9, 24, 9);
    db = openTestDatabase();
    entries = studyEntryRepository(db, () => clock);
    sessions = studySessionRepository(db, () => clock);
  });
  tearDown(() => db.close());

  Future<String> opened() async {
    final decks = DeckRepositoryImpl(db, now: () => clock);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id);
    final result = await entries.openLearningSession(deckId: leaf.id);
    return (result as Ok<String, StudyRejection>).value;
  }

  Future<String> statusOf(String sessionId) async =>
      (await sessionOf(db, sessionId)).read<String>('status');

  test('AbandonStudySession leaves the session (UC-STUDY-001 A3)', () async {
    final id = await opened();

    final result = await AbandonStudySessionUseCase(sessions)(sessionId: id);

    expect(result, isA<Ok<void, StudyRejection>>());
    expect(await statusOf(id), 'abandoned');
  });

  test('ResumeStudySession continues a session of the same day '
      '(UC-STUDY-001 A3b)', () async {
    final id = await opened();

    final result = await ResumeStudySessionUseCase(sessions)(sessionId: id);

    expect(result, isA<Ok<void, StudyRejection>>());
    expect(await statusOf(id), 'in_progress');
  });

  test('AbandonStaleSessions closes the sessions of earlier days '
      '(BR-STUDY-072)', () async {
    final id = await opened();
    clock = DateTime(2026, 9, 25, 7);

    await AbandonStaleSessionsUseCase(sessions)();

    expect(await statusOf(id), 'abandoned');
  });
}

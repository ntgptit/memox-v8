import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
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

// UC-STUDY-001 A4: the summary of a review cut at its card limit says how
// many cards of its tree are still due.

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudySessionViewRepositoryImpl views;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    views = StudySessionViewRepositoryImpl(db, now: () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudySessionView> viewOf(String sessionId) async =>
      (await views.watchSession(sessionId).first)!;

  Future<(DeckEntity, DeckEntity)> tree() async {
    final root = await decks.root('Korean', SchedulerType.eightBox);
    return (root, await decks.sub(root.id, 'Lesson'));
  }

  test('a review that reached its card_limit counts the cards of its tree '
      'still due, and none below the limit (UC-STUDY-001 A4)', () async {
    final (root, leaf) = await tree();
    Future<void> due(String id) => insertCard(
      db,
      id: id,
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
      box: 3,
    );
    for (final id in ['a', 'b', 'c']) {
      await due(id);
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    // Two more fall due past the three the session took, at its limit.
    for (final extra in ['d', 'e']) {
      await due(extra);
    }
    await db.customStatement(
      'UPDATE study_session SET card_limit = 3 WHERE id = ?',
      [id],
    );
    for (var i = 0; i < 3; i++) {
      await answerServed(db, sessions, id, right: true);
    }

    final summary = (await viewOf(id)).summary!;
    expect((summary.isAtCardLimit, summary.remainingDueCount), (true, 2));

    // Told to the stream store, so the watch reads the row again.
    await db.customUpdate(
      'UPDATE study_session SET card_limit = 20 WHERE id = ?',
      variables: [Variable<String>(id)],
      updates: {db.studySession},
    );
    expect((await viewOf(id)).summary!.remainingDueCount, 0);
  });
}

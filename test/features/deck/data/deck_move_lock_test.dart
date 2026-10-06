import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// DEV-213: the scheduler lock follows the subtree (BR-SRS-003, BR-SRS-006,
// invariant 30). A sub-deck holding a learned card moved, restored or undone
// into a root that is not locked locks that root in the same transaction, so
// its scheduler can no longer be changed under the learned cards.

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ScheduleRepositoryImpl srs;
  var clock = DateTime(2026, 10, 6, 9);

  setUp(() async {
    clock = DateTime(2026, 10, 6, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    srs = ScheduleRepositoryImpl(db, now: () => clock);
    // Root a with leaf a-leaf and card a-card, learned: a is locked.
    final (_, cardId, sessionId) = await insertStudyTree(db, 'a');
    await srs.completeLearning(cardId: cardId, generation: 1);
    await db.customStatement(
      "UPDATE study_session SET status = 'completed', ended_at = 1 WHERE id = ?",
      [sessionId],
    );
    // Root b: same scheduler and generation, nothing learned, not locked.
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES ('b', 'b', NULL, 'b', 1, 'deck', 'eight_box', 1, 1, 1, 0, 0)",
    );
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<int?> lockOf(String rootId) async =>
      (await deckRowOf(db, rootId)).readNullable<int>('first_answered_at');

  Future<String> trashLeaf() async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: 'a-leaf',
    )) as Ok<String, DeckRejection>).value;
  }

  Future<void> expectLocked(String rootId) async {
    expect(await lockOf(rootId), isNotNull, reason: '$rootId is locked');
    expect(
      await srs.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2),
      isA<Rejected<void, SrsRejection>>().having(
        (r) => r.reason,
        'reason',
        SrsRejection.schedulerLocked,
      ),
    );
    final schedule = await scheduleRowOf(db, 'a-card');
    expect(schedule.readNullable<int>('learned_at'), isNotNull);
  }

  test('moving a learned sub-deck into an unlocked root locks it', () async {
    expect(await lockOf('b'), isNull);

    final result = await decks.moveDeck(deckId: 'a-leaf', newParentId: 'b');

    expect(result, isA<Ok<void, DeckRejection>>());
    await expectLocked('b');
  });

  test('restoring a learned sub-deck into an unlocked root locks it', () async {
    final batch = await trashLeaf();

    final result = await decks.restoreDecks(batchIds: {batch}, parentId: 'b');

    expect(result, isA<Ok<void, DeckRejection>>());
    await expectLocked('b');
  });

  test(
    'undoing the deletion of a learned sub-deck locks its root again',
    () async {
      final batch = await trashLeaf();
      // The root lost its lock while the sub-deck was in the Trash.
      await db.customStatement(
        "UPDATE deck SET first_answered_at = NULL WHERE id = 'a'",
      );

      final result = await decks.undoDeckDeletion(batchId: batch);

      expect(result, isA<Ok<void, DeckRejection>>());
      await expectLocked('a');
    },
  );

  test('a sub-deck with nothing learned locks no root', () async {
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) VALUES ('a-new', 'new', 'a', 'a', 2, 'unset', 1, 0, 0)",
    );

    final result = await decks.moveDeck(deckId: 'a-new', newParentId: 'b');

    expect(result, isA<Ok<void, DeckRejection>>());
    expect(await lockOf('b'), isNull);
  });
}

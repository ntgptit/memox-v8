import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// BR-TRASH-009 and BR-TRASH-010: a purge deletes chosen and expired batches
// for good, by cascade, oldest first, and skips whole a batch that still
// holds rows of another (trash spec §8).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TrashRepositoryImpl trash;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => clock),
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
    trash = TrashRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<String> deleteDeck(String deckId) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: deckId,
    )) as Ok<String, DeckRejection>).value;
  }

  Future<String> deleteCard(String cardId) async {
    clock = clock.add(const Duration(minutes: 1));
    final [batchId] = ((await cards.deleteCards(
      cardIds: {cardId},
    )) as Ok<List<String>, CardRejection>).value;
    return batchId;
  }

  Future<int> countOf(String sql) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $sql').getSingle())
          .read<int>('n');

  void expectReport(
    PurgeReport report, {
    Set<String> purged = const {},
    Map<String, Set<String>> blocked = const {},
    Set<String> missing = const {},
  }) {
    expect(report.purged, purged);
    expect(report.blocked, blocked);
    expect(report.missing, missing);
  }

  test('a purge deletes exactly the batch and what hangs on its rows: '
      'schedules, logs, tag links, sessions and queues (BR-TRASH-010)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    final kept = await decks.sub(root.id, 'Kept');
    for (final (id, deckId) in [('c1', lesson.id), ('k1', kept.id)]) {
      await insertCard(
        db,
        id: id,
        deckId: deckId,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 30),
      );
    }
    await insertCard(db, id: 'c2', deckId: lesson.id);
    await lockScheduler(db, root.id);
    await logReview(db, id: 'l1', cardId: 'c1', at: DateTime(2026, 9, 2));
    await logReview(db, id: 'l2', cardId: 'k1', at: DateTime(2026, 9, 2));
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 't', 't', 0)",
    );
    await db.customStatement(
      "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't'), ('k1', 't')",
    );
    final opened = await studyEntryRepository(
      db,
      () => clock,
    ).openLearningSession(deckId: lesson.id);
    expect(opened, isA<Ok<String, StudyRejection>>());
    final batchId = await deleteDeck(lesson.id);

    final report = await trash.purge(batchIds: {batchId}, now: clock);

    expectReport(report, purged: {batchId});
    expect(await countOf('delete_batches'), 0);
    expect(await countOf("deck WHERE id = '${lesson.id}'"), 0);
    expect(await countOf("card WHERE id = 'c1'"), 0);
    expect(await countOf("card_schedule WHERE card_id = 'c1'"), 0);
    expect(await countOf("review_log WHERE card_id = 'c1'"), 0);
    expect(await countOf("card_tags WHERE card_id = 'c1'"), 0);
    expect(await countOf('study_session'), 0);
    expect(await countOf('study_queue_items'), 0);
    expect(await countOf("card WHERE id = 'k1'"), 1);
    expect(await countOf('review_log'), 1);
    expect(await countOf('card_tags'), 1);
  });

  test(
    'a deck holding a batch that is not chosen is skipped whole and '
    'reported with it; a missing id is reported (BR-TRASH-010, E4, E6)',
    () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      await insertCard(db, id: 'c1', deckId: food.id);
      final inner = await deleteCard('c1');
      final outer = await deleteDeck(words.id);

      final report = await trash.purge(batchIds: {outer, 'gone'}, now: clock);

      expectReport(
        report,
        blocked: {
          outer: {inner},
        },
        missing: {'gone'},
      );
      expect(await countOf('delete_batches'), 2);
      expect(await countOf("deck WHERE id = '${food.id}'"), 1);
    },
  );

  test('choosing the inner batch too purges both in one call; when the '
      'outer one sorts first, a second pass takes it', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    await insertCard(db, id: 'c1', deckId: words.id);
    final inner = await deleteCard('c1');
    final outer = await deleteDeck(words.id);
    await db.customStatement(
      "UPDATE delete_batches SET deleted_at = 0 WHERE id = '$outer'",
    );

    final report = await trash.purge(batchIds: {outer, inner}, now: clock);

    expect(report.purged, {outer, inner});
    expect(report.blocked, isEmpty);
    expect(await countOf('delete_batches'), 0);
  });

  test('expiry: 720 hours after a delete the batch goes, a millisecond '
      'earlier it stays; a second run purges nothing (BR-TRASH-009)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    final deletedAt = clock.add(const Duration(minutes: 1));
    final batchId = await deleteDeck(words.id);
    expect(clock, deletedAt);

    final early = await trash.purgeExpired(
      now: deletedAt.add(trashRetention - const Duration(milliseconds: 1)),
    );
    expect(early.purged, isEmpty);

    final due = await trash.purgeExpired(now: deletedAt.add(trashRetention));
    expect(due.purged, {batchId});

    final again = await trash.purgeExpired(now: deletedAt.add(trashRetention));
    expectReport(again);
  });

  test('1,000 cards deleted in one call expire together, and one auto-purge '
      'takes every batch (BR-TRASH-009)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    final ids = {for (var i = 0; i < 1000; i++) 'c$i'};
    for (final id in ids) {
      await insertCard(db, id: id, deckId: lesson.id);
    }
    clock = clock.add(const Duration(minutes: 1));
    final batchIds = ((await cards.deleteCards(
      cardIds: ids,
    )) as Ok<List<String>, CardRejection>).value;

    final report = await trash.purgeExpired(now: clock.add(trashRetention));

    expectReport(report, purged: batchIds.toSet());
    expect(await countOf('card'), 0);
    expect(await countOf('card_schedule'), 0);
  });

  test('a manual purge takes the expired batches too', () async {
    final root = await decks.root('Korean');
    final old = await deleteDeck((await decks.sub(root.id, 'Old')).id);
    final oldAt = clock;
    final fresh = await deleteDeck((await decks.sub(root.id, 'Fresh')).id);
    final chosen = await deleteDeck((await decks.sub(root.id, 'Chosen')).id);

    final report = await trash.purge(
      batchIds: {chosen},
      now: oldAt.add(trashRetention),
    );

    expectReport(report, purged: {old, chosen});
    expect(await countOf("delete_batches WHERE id = '$fresh'"), 1);
  });

  test('an error half-way rolls the whole purge back (E5)', () async {
    final root = await decks.root('Korean');
    final first = await deleteDeck((await decks.sub(root.id, 'First')).id);
    final second = await decks.sub(root.id, 'Second');
    final secondBatch = await deleteDeck(second.id);
    await db.customStatement(
      'CREATE TEMP TRIGGER fail_purge BEFORE DELETE ON deck '
      "WHEN OLD.id = '${second.id}' BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );

    await expectLater(
      trash.purge(batchIds: {first, secondBatch}, now: clock),
      throwsA(isA<Failure>()),
    );

    expect(await countOf('delete_batches'), 2);
    await db.customStatement('DROP TRIGGER fail_purge');
  });
}

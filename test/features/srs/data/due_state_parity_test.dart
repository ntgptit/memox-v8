import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/datasources/card_list_dao.dart';
import 'package:memox/features/card/data/mappers/card_mapper.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/reminders/data/datasources/reminder_workload_dao.dart';
import 'package:memox/features/srs/domain/models/due_state_model.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// DEV-221, BR-STUDY-068: the due sets have one SQL copy (CardDueSql, taken
// by the deck level, the Study Entry, Study Home, the reminder and the card
// list) and one Dart copy (dueStateOf, behind CardDue and the card list
// workload). Over one set of cards, every reader names the same numbers, so
// neither side can move alone. The set holds the row invariant 24 forbids
// (learned, no due date): it rests, everywhere.

final _now = DateTime(2026, 9, 23, 10);
final _today = DateTime(2026, 9, 23);
final _learned = DateTime(2026, 9, 1);

void main() {
  late AppDatabase db;
  late String rootId;
  late String leafId;

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Leaf');
    rootId = root.id;
    leafId = leaf.id;
    Future<void> card(String id, {DateTime? learnedAt, DateTime? dueAt}) =>
        insertCard(
          db,
          id: id,
          deckId: leafId,
          learnedAt: learnedAt,
          dueAt: dueAt,
        );
    await card('new');
    await card('overdue', learnedAt: _learned, dueAt: DateTime(2026, 9, 20));
    await card('today-start', learnedAt: _learned, dueAt: _today);
    await card('today-now', learnedAt: _learned, dueAt: _now);
    await card('tomorrow', learnedAt: _learned, dueAt: DateTime(2026, 9, 24));
    await card('resting-no-date', learnedAt: _learned);
    await insertCard(
      db,
      id: 'trashed',
      deckId: leafId,
      learnedAt: _learned,
      dueAt: DateTime(2026, 9, 20),
      deleteBatchId: 'b',
    );
  });
  tearDown(() => db.close());

  /// (new, overdue, due today, scheduled) over the leaf's live schedule
  /// rows, through the Dart rule.
  Future<(int, int, int, int)> dartCounts() async {
    final counts = <DueState, int>{};
    for (final s in await CardListDao(db).activeSchedules(leafId)) {
      final state = dueStateOf(
        learnedAt: s.learnedAt,
        dueAt: s.dueAt,
        now: _now,
        startOfToday: _today,
      );
      counts[state] = (counts[state] ?? 0) + 1;
    }
    return (
      counts[DueState.newCard] ?? 0,
      counts[DueState.overdue] ?? 0,
      counts[DueState.dueToday] ?? 0,
      counts[DueState.scheduled] ?? 0,
    );
  }

  test('the Dart rule sorts the fixture as BR-STUDY-068 says', () async {
    expect(await dartCounts(), (1, 1, 2, 2));
  });

  test('the deck level, Study Home and the reminder count the same sets as '
      'the Dart rule', () async {
    final dart = await dartCounts();
    final [tile] = await DeckRepositoryImpl(db)
        .watchLevel(parentId: null, now: _now, startOfToday: _today)
        .first;
    final [home] = await StudyViewDao(db)
        .rootDeckRows(now: _now, startOfToday: _today);
    final [reminder] = await ReminderWorkloadDao(db)
        .rootDeckRows(now: _now, startOfToday: _today);

    expect((
      tile.newCount,
      tile.overdueCount,
      tile.dueTodayCount,
      tile.scheduledCount,
    ), dart);
    expect(tile.oldestDueAt, DateTime(2026, 9, 20));
    expect((
      home.newCount,
      home.overdueCount,
      home.dueTodayCount,
      home.cardCount - home.newCount - home.overdueCount - home.dueTodayCount,
    ), dart);
    expect((
      reminder.newCount,
      reminder.overdueCount,
      reminder.dueTodayCount,
      reminder.cardCount -
          reminder.newCount -
          reminder.overdueCount -
          reminder.dueTodayCount,
    ), dart);
  });

  test('the Study Entry counts, the next due date and the card list count '
      'the same sets as the Dart rule', () async {
    final (newCards, overdue, dueToday, _) = await dartCounts();
    final entry = await StudySessionDao(db)
        .subtreeCounts(rootId, _now, startOfToday: _today);
    final list = await CardListDao(db)
        .counts(deckId: leafId, searchTerm: '', tagIds: const {}, now: _now);
    final workload = workloadOf(
      await CardListDao(db).activeSchedules(leafId),
      now: _now,
      startOfToday: _today,
    );

    expect(
      (entry.newCount, entry.overdueCount, entry.dueCount),
      (newCards, overdue, overdue + dueToday),
    );
    expect(entry.nextDueAt, DateTime(2026, 9, 24));
    expect(await StudyViewDao(db).nextDueAt(now: _now), DateTime(2026, 9, 24));
    expect((list.newCards, list.due), (newCards, overdue + dueToday));
    expect(
      (workload.newCards, workload.overdue, workload.today),
      (newCards, overdue, dueToday),
    );
    expect(
      [
        for (final row in await StudySessionDao(db).newCards(rootId))
          row.cardId,
      ],
      ['new'],
    );
    expect(
      [
        for (final row in await StudySessionDao(db).dueCards(rootId, _now))
          row.cardId,
      ],
      ['overdue', 'today-start', 'today-now'],
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/datasources/card_list_dao.dart';
import 'package:memox/features/card/data/mappers/card_mapper.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/due_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// DEV-211, BR-CARD-008, BR-SRS-013, BR-STUDY-068: the card list's status
// counts and workload are one SQL statement (deckStatusCounts, through
// CardStatusSql and CardDueSql); CardDisplayStatus.of and dueStateOf are the
// Dart rule. Over one set of cards at every threshold, both name the same
// numbers, so neither side can move alone.

final _now = DateTime(2026, 9, 23, 10);
final _today = DateTime(2026, 9, 23);
final _learned = DateTime(2026, 5, 1);
final _overdueAt = DateTime(2026, 9, 20);
final _tomorrow = DateTime(2026, 9, 24);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardListDao dao;

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    dao = CardListDao(db);
  });
  tearDown(() => db.close());

  /// (new, beginning, reviewing, mastered) and (overdue, today, new) over
  /// the deck's live rows, through the Dart rule.
  Future<((int, int, int, int), (int, int, int))> dart(String deckId) async {
    final status = <CardDisplayStatus, int>{};
    final due = <DueState, int>{};
    for (final s in await liveSchedulesOf(db, deckId)) {
      final display = CardDisplayStatus.of(scheduleStateOf(s));
      status[display] = (status[display] ?? 0) + 1;
      final set = dueStateOf(
        learnedAt: s.learnedAt,
        dueAt: s.dueAt,
        now: _now,
        startOfToday: _today,
      );
      due[set] = (due[set] ?? 0) + 1;
    }
    return (
      (
        status[CardDisplayStatus.newCard] ?? 0,
        status[CardDisplayStatus.beginning] ?? 0,
        status[CardDisplayStatus.reviewing] ?? 0,
        status[CardDisplayStatus.mastered] ?? 0,
      ),
      (
        due[DueState.overdue] ?? 0,
        due[DueState.dueToday] ?? 0,
        due[DueState.newCard] ?? 0,
      ),
    );
  }

  Future<((int, int, int, int), (int, int, int))> sql(String deckId) async {
    final row = await dao.statusCounts(deckId, now: _now, startOfToday: _today);
    final counts = statusCountsOf(row);
    final workload = workloadOf(row);
    return (
      (counts.newCards, counts.beginning, counts.reviewing, counts.mastered),
      (workload.overdue, workload.today, workload.newCards),
    );
  }

  test('eight boxes: boxes 1 and 3 are beginning, 4 and 7 reviewing, 8 '
      'mastered, an unlearned card new, a trashed card nothing', () async {
    final root = await decks.root('Boxes');
    final leaf = await decks.sub(root.id, 'Leaf');
    Future<void> card(String id, {int box = 1, DateTime? dueAt}) => insertCard(
      db,
      id: id,
      deckId: leaf.id,
      learnedAt: _learned,
      dueAt: dueAt ?? _tomorrow,
      box: box,
    );
    await card('b1', box: 1, dueAt: _overdueAt);
    await card('b3', box: 3, dueAt: _today);
    await card('b4', box: 4, dueAt: _now);
    await card('b7', box: 7);
    await card('b8', box: 8);
    await insertCard(db, id: 'new8', deckId: leaf.id, box: 8);
    await insertCard(
      db,
      id: 'trashed',
      deckId: leaf.id,
      learnedAt: _learned,
      dueAt: _overdueAt,
      box: 8,
      deleteBatchId: 'b',
    );

    final expected = ((1, 2, 2, 1), (1, 2, 1));
    expect(await dart(leaf.id), expected);
    expect(await sql(leaf.id), expected);
  });

  test('SM-2: 1 and 7 days are beginning, 8 and 127 reviewing, 128 '
      'mastered, an unlearned card new', () async {
    final root = await decks.root('Days', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Leaf');
    Future<void> card(String id, {int days = 1, DateTime? dueAt}) => insertCard(
      db,
      id: id,
      deckId: leaf.id,
      learnedAt: _learned,
      dueAt: dueAt ?? _tomorrow,
      intervalDays: days,
    );
    await card('d1', days: 1, dueAt: _overdueAt);
    await card('d7', days: 7, dueAt: _overdueAt);
    await card('d8', days: 8, dueAt: _today);
    await card('d127', days: 127);
    await card('d128', days: 128);
    await insertCard(db, id: 'new', deckId: leaf.id);

    final expected = ((1, 2, 2, 1), (2, 1, 1));
    expect(await dart(leaf.id), expected);
    expect(await sql(leaf.id), expected);
  });

  test('a deck with no card counts zero everywhere', () async {
    final root = await decks.root('Empty');
    final leaf = await decks.sub(root.id, 'Leaf');

    expect(await sql(leaf.id), ((0, 0, 0, 0), (0, 0, 0)));
  });
}

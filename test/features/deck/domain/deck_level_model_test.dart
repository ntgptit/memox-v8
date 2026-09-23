import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

final _today = DateTime(2026, 9, 23);

DeckTile _tile(
  String id, {
  String? name,
  int position = 0,
  DateTime? createdAt,
  int cards = 0,
  int newCards = 0,
  int overdue = 0,
  int dueToday = 0,
  DateTime? oldestDueAt,
}) => DeckTile(
  id: id,
  name: name ?? id,
  siblingPosition: position,
  createdAt: createdAt ?? DateTime(2026, 9, 1),
  schedulerType: SchedulerType.eightBox,
  subDeckCount: 0,
  cardCount: cards,
  newCount: newCards,
  overdueCount: overdue,
  dueTodayCount: dueToday,
  oldestDueAt: oldestDueAt,
  startOfToday: _today,
);

List<String> _ids(DeckLevel level) => [for (final tile in level.tiles) tile.id];

void main() {
  group('DeckTile', () {
    test(
      'Due is Overdue plus Due today; Scheduled is the rest after New and Due',
      () {
        final tile = _tile(
          't',
          cards: 10,
          newCards: 3,
          overdue: 2,
          dueToday: 1,
        );
        expect((tile.dueCount, tile.scheduledCount), (3, 4));
      },
    );

    test('its schedule status and overdue days come from the oldest Due card (BR-STUDY-067)', () {
      final overdue = _tile(
        'o',
        overdue: 1,
        oldestDueAt: DateTime(2026, 9, 20),
      );
      final dueToday = _tile('d', dueToday: 1, oldestDueAt: _today);
      final notDue = _tile('n');

      expect(
        (overdue.scheduleStatus, overdue.overdueDays),
        (DeckScheduleStatus.overdue, 3),
      );
      expect(
        (dueToday.scheduleStatus, dueToday.overdueDays),
        (DeckScheduleStatus.dueToday, 0),
      );
      expect(
        (notDue.scheduleStatus, notDue.overdueDays),
        (DeckScheduleStatus.notDue, 0),
      );
    });
  });

  group('DeckLevelSort (UC-DECK-003, IT-DISC-005)', () {
    final beta = _tile(
      'b',
      name: 'beta',
      position: 0,
      createdAt: DateTime(2026, 9, 1),
    );
    final alpha = _tile(
      'a',
      name: 'Alpha',
      position: 1,
      createdAt: DateTime(2026, 9, 2),
    );
    final gamma = _tile(
      'g',
      name: 'gamma',
      position: 2,
      createdAt: DateTime(2026, 9, 3),
    );
    final tiles = [gamma, alpha, beta];

    test('manual follows the sibling position', () {
      expect(_ids(DeckLevel.of(tiles)), ['b', 'a', 'g']);
    });

    test('name ignores case', () {
      expect(_ids(DeckLevel.of(tiles, sort: DeckLevelSort.name)), [
        'a',
        'b',
        'g',
      ]);
    });

    test('recent puts the newest deck first', () {
      expect(_ids(DeckLevel.of(tiles, sort: DeckLevelSort.recent)), [
        'g',
        'a',
        'b',
      ]);
    });

    test('due puts the most Due cards first, then the manual order', () {
      final level = DeckLevel.of([
        _tile('x', position: 0),
        _tile('y', position: 1, dueToday: 1),
        _tile('z', position: 2, overdue: 2, dueToday: 1),
        _tile('w', position: 3, dueToday: 1),
      ], sort: DeckLevelSort.due);
      expect(_ids(level), ['z', 'y', 'w', 'x']);
    });

    test('equal names keep the manual order', () {
      final level = DeckLevel.of([
        _tile('second', name: 'Same', position: 1),
        _tile('first', name: 'same', position: 0),
      ], sort: DeckLevelSort.name);
      expect(_ids(level), ['first', 'second']);
    });
  });

  group('DeckLevelFilter and the level summary', () {
    final mixed = _tile(
      'mixed',
      position: 0,
      cards: 4,
      newCards: 1,
      overdue: 1,
      dueToday: 1,
      oldestDueAt: DateTime(2026, 9, 22),
    );
    final future = _tile('future', position: 1, cards: 1);

    test('due keeps the decks with a Due card (IT-DISC-003)', () {
      expect(_ids(DeckLevel.of([mixed, future], filter: DeckLevelFilter.due)), [
        'mixed',
      ]);
      expect(
        DeckLevel.of([future], filter: DeckLevelFilter.due).tiles,
        isEmpty,
      );
    });

    test('the summary counts every deck of the level, whatever the filter (BR-STUDY-068)', () {
      final level = DeckLevel.of([mixed, future], filter: DeckLevelFilter.due);
      expect(
        (
          level.overdueCount,
          level.dueTodayCount,
          level.newCount,
          level.scheduledCount,
        ),
        (1, 1, 1, 2),
      );
      expect(level.maxOverdueDays, 1);
    });
  });
}

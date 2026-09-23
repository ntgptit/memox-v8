import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// One deck of a level with the counts of its whole subtree (UC-DECK-003).
/// New and Due are never merged (BR-STUDY-046); the counts are as of the
/// local day that starts at [startOfToday] (BR-STUDY-068).
final class DeckTile {
  const DeckTile({
    required this.id,
    required this.name,
    required this.siblingPosition,
    required this.createdAt,
    required this.schedulerType,
    required this.subDeckCount,
    required this.cardCount,
    required this.newCount,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.oldestDueAt,
    required this.startOfToday,
  });

  final String id;
  final String name;
  final int siblingPosition;
  final DateTime createdAt;

  /// The scheduler of the deck's root (BR-DECK-024).
  final SchedulerType schedulerType;

  /// The decks directly under this one.
  final int subDeckCount;
  final int cardCount;
  final int newCount;
  final int overdueCount;
  final int dueTodayCount;

  /// The `due_at` of the subtree's oldest Due card; null when none is Due.
  final DateTime? oldestDueAt;
  final DateTime startOfToday;

  int get dueCount => overdueCount + dueTodayCount;

  /// Learned cards not Due yet: the neutral set (BR-STUDY-068).
  int get scheduledCount => cardCount - newCount - dueCount;

  DeckScheduleStatus get scheduleStatus =>
      DeckScheduleStatus.of(oldestDueAt, startOfToday);

  int get overdueDays =>
      DeckScheduleStatus.overdueDays(oldestDueAt, startOfToday);
}

/// A level of the tree as the person asked for it, and the summary of every
/// deck on it whatever the filter: the four disjoint sets of BR-STUDY-068 and
/// the longest overdue run (BR-STUDY-067).
final class DeckLevel {
  const DeckLevel._({
    required this.tiles,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.newCount,
    required this.scheduledCount,
    required this.maxOverdueDays,
  });

  factory DeckLevel.of(
    List<DeckTile> tiles, {
    DeckLevelSort sort = DeckLevelSort.manual,
    DeckLevelFilter filter = DeckLevelFilter.all,
  }) {
    int sum(int Function(DeckTile tile) count) =>
        tiles.fold(0, (total, tile) => total + count(tile));
    return DeckLevel._(
      tiles: sort.apply([
        for (final tile in tiles)
          if (filter.keeps(tile)) tile,
      ]),
      overdueCount: sum((tile) => tile.overdueCount),
      dueTodayCount: sum((tile) => tile.dueTodayCount),
      newCount: sum((tile) => tile.newCount),
      scheduledCount: sum((tile) => tile.scheduledCount),
      maxOverdueDays: tiles.fold(
        0,
        (longest, tile) =>
            tile.overdueDays > longest ? tile.overdueDays : longest,
      ),
    );
  }

  final List<DeckTile> tiles;
  final int overdueCount;
  final int dueTodayCount;
  final int newCount;
  final int scheduledCount;
  final int maxOverdueDays;
}

import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

/// UC-DECK-003: a level of the tree with its counts, again on every change
/// and at every local midnight, when Due today becomes Overdue with no write
/// (BR-STUDY-067, BR-STUDY-068).
final class WatchDeckLevelUseCase {
  const WatchDeckLevelUseCase(this._decks, this._clock);

  final DeckRepository _decks;
  final DayClock _clock;

  /// The roots when [parentId] is null.
  Stream<DeckLevel> call({
    String? parentId,
    DeckLevelSort sort = DeckLevelSort.manual,
    DeckLevelFilter filter = DeckLevelFilter.all,
  }) => watchEachLocalDay(
    _clock,
    (now) => _decks
        .watchLevel(
          parentId: parentId,
          now: now,
          startOfToday: startOfLocalDay(now),
        )
        .map((tiles) => DeckLevel.of(tiles, sort: sort, filter: filter)),
  );
}

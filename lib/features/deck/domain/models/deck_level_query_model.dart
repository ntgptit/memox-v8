import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';

/// How a level is ordered (UC-DECK-003, UC-DECK-006). Every order ends in the
/// manual one, `(sibling_position, id)`, so equal keys stay stable. The
/// "progress" order UC-DECK-006 names has no definition yet and is not here.
enum DeckLevelSort {
  manual,

  /// Folded name, so case does not matter (IT-DISC-005).
  name,

  /// Newest `created_at` first.
  recent,

  /// Most Due cards first.
  due;

  List<DeckTile> apply(List<DeckTile> tiles) => [...tiles]..sort(_compare);

  int _compare(DeckTile a, DeckTile b) {
    final byKey = switch (this) {
      manual => 0,
      name => foldText(a.name).compareTo(foldText(b.name)),
      recent => b.createdAt.compareTo(a.createdAt),
      due => b.dueCount.compareTo(a.dueCount),
    };
    if (byKey != 0) return byKey;
    final byPosition = a.siblingPosition.compareTo(b.siblingPosition);
    if (byPosition != 0) return byPosition;
    return a.id.compareTo(b.id);
  }
}

/// Which decks of a level are shown (IT-DISC-003).
enum DeckLevelFilter {
  all,

  /// Decks with at least one Due card.
  due;

  bool keeps(DeckTile tile) => switch (this) {
    all => true,
    due => tile.dueCount > 0,
  };
}

import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';

/// How a level is ordered (UC-DECK-003, UC-DECK-006). Every order ends in the
/// manual one, `(sibling_position, id)`, so equal keys stay stable.
enum DeckLevelSort {
  manual,

  /// Folded name, so case does not matter (IT-DISC-005).
  name,

  /// Newest `created_at` first.
  recent,

  /// Most Due cards first.
  due,

  /// Least mastered first; decks with no card last (BR-DECK-027).
  progress;

  List<DeckTile> apply(List<DeckTile> tiles) => [...tiles]..sort(_compare);

  int _compare(DeckTile a, DeckTile b) {
    final byKey = switch (this) {
      manual => 0,
      name => foldText(a.name).compareTo(foldText(b.name)),
      recent => b.createdAt.compareTo(a.createdAt),
      due => b.dueCount.compareTo(a.dueCount),
      progress => _byMastery(a, b),
    };
    if (byKey != 0) return byKey;
    final byPosition = a.siblingPosition.compareTo(b.siblingPosition);
    if (byPosition != 0) return byPosition;
    return a.id.compareTo(b.id);
  }

  /// Compares the fractions by cross-multiplication, so 1/2 and 2/4 are
  /// equal without floating point (BR-DECK-027).
  static int _byMastery(DeckTile a, DeckTile b) {
    final aEmpty = a.cardCount == 0;
    final bEmpty = b.cardCount == 0;
    if (aEmpty || bEmpty) return aEmpty == bEmpty ? 0 : (aEmpty ? 1 : -1);
    return (a.masteredCount * b.cardCount).compareTo(
      b.masteredCount * a.cardCount,
    );
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

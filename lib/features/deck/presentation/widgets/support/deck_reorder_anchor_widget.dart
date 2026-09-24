import 'package:memox/features/deck/domain/models/deck_placement_model.dart';

/// The sibling a dragged deck lands next to (UC-DECK-006), from a
/// `ReorderableListView` drop of the deck at [oldIndex] to [newIndex] over
/// [ids]. Null when the drop leaves it where it was.
({String anchorId, DeckPlacement placement})? deckReorderAnchor(
  List<String> ids,
  int oldIndex,
  int newIndex,
) {
  // The list reports [newIndex] as if the dragged deck were still in place.
  final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
  if (target == oldIndex) return null;
  final rest = [...ids]..removeAt(oldIndex);
  if (target == 0) {
    return (anchorId: rest.first, placement: DeckPlacement.before);
  }
  return (anchorId: rest[target - 1], placement: DeckPlacement.after);
}

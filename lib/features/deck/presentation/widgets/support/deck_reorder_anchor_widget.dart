import 'package:memox/features/deck/domain/models/deck_placement_model.dart';

/// The sibling a dragged deck lands next to (UC-DECK-006), from a
/// `ReorderableListView.onReorderItem` drop of the deck at [oldIndex] to its
/// final place [newIndex] among [ids]. Null when it stays where it was.
({String anchorId, DeckPlacement placement})? deckReorderAnchor(
  List<String> ids,
  int oldIndex,
  int newIndex,
) {
  if (newIndex == oldIndex) return null;
  final rest = [...ids]..removeAt(oldIndex);
  if (newIndex == 0) {
    return (anchorId: rest.first, placement: DeckPlacement.before);
  }
  return (anchorId: rest[newIndex - 1], placement: DeckPlacement.after);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_path_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_reorder_anchor_widget.dart';

const _ids = ['a', 'b', 'c'];

void main() {
  test('moving down lands after the deck it passed', () {
    // ReorderableListView reports 2 for "a" dropped between "b" and "c".
    expect(deckReorderAnchor(_ids, 0, 2), (
      anchorId: 'b',
      placement: DeckPlacement.after,
    ));
  });

  test('moving to the top lands before the first deck', () {
    expect(deckReorderAnchor(_ids, 2, 0), (
      anchorId: 'a',
      placement: DeckPlacement.before,
    ));
  });

  test('moving to the end lands after the last deck', () {
    expect(deckReorderAnchor(_ids, 0, 3), (
      anchorId: 'c',
      placement: DeckPlacement.after,
    ));
  });

  test('a drop where it started moves nothing', () {
    expect(deckReorderAnchor(_ids, 1, 1), isNull);
    expect(deckReorderAnchor(_ids, 1, 2), isNull);
  });

  test('a path reads root first', () {
    expect(deckPathLabel(['Korean', 'Words']), 'Korean › Words');
  });
}

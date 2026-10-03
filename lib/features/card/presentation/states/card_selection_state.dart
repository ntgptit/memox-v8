import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_selection_state.g.dart';

/// The cards picked in a deck's selection mode (BR-CARD-020). Empty means
/// the list is not selecting.
@riverpod
class CardSelection extends _$CardSelection {
  @override
  Set<String> build(String deckId) => const {};

  void toggle(String cardId) => state = state.contains(cardId)
      ? ({...state}..remove(cardId))
      : {...state, cardId};

  void selectAll(Set<String> cardIds) => state = {...cardIds};

  /// Drops ids a bulk action found already gone, so they do not stay
  /// selected (SP2a 2.19).
  void prune(Set<String> gone) {
    if (gone.isEmpty) return;
    state = state.difference(gone);
  }

  void clear() => state = const {};
}

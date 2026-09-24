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

  void clear() => state = const {};
}

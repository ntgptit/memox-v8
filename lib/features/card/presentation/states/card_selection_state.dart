import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_selection_state.g.dart';

/// A deck's selection mode (BR-CARD-020): whether the list is selecting,
/// and the cards picked. A long-press on a row enters it with that card;
/// "Select cards" from the deck's ⋮ enters it with none (DEV-307). It
/// ends only with Close, so unticking the last card keeps the mode, as the
/// Trash does. Picks exist only while selecting: [CardSelection] is the
/// one writer and keeps it so.
@immutable
final class CardSelectionState {
  const CardSelectionState({this.isSelecting = false, this.ids = const {}});

  static const CardSelectionState none = CardSelectionState();

  final bool isSelecting;
  final Set<String> ids;

  bool contains(String cardId) => ids.contains(cardId);
}

@riverpod
class CardSelection extends _$CardSelection {
  @override
  CardSelectionState build(String deckId) => CardSelectionState.none;

  /// Enters selection with nothing picked.
  void start() => state = const CardSelectionState(isSelecting: true);

  void toggle(String cardId) => state = CardSelectionState(
    isSelecting: true,
    ids: state.contains(cardId)
        ? ({...state.ids}..remove(cardId))
        : {...state.ids, cardId},
  );

  void selectAll(Set<String> cardIds) =>
      state = CardSelectionState(isSelecting: true, ids: {...cardIds});

  void clear() => state = CardSelectionState.none;
}

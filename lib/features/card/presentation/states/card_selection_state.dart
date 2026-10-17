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

  /// Drops the picks in [checked] that are not in [liveIds]: cards that left
  /// the list while picked. A bulk action over a card that is gone is
  /// refused whole. A pick made after [checked] was taken was not read
  /// against [liveIds] and stays.
  void retain(Set<String> liveIds, {required Set<String> checked}) {
    final kept = state.ids.difference(checked.difference(liveIds));
    if (!state.isSelecting || kept.length == state.ids.length) return;
    state = CardSelectionState(isSelecting: true, ids: kept);
  }

  void clear() => state = CardSelectionState.none;
}

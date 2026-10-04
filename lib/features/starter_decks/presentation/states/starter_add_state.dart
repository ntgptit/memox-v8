import 'package:flutter/foundation.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';

/// The algorithm sheet's add (FE-B4 spec D6): running, or failed with the
/// sheet still open (`addFailed`).
@immutable
final class StarterAddState {
  const StarterAddState({this.isAdding = false, this.hasFailed = false});

  /// The options and Cancel lock, and "Add deck" spins (`adding`).
  final bool isAdding;

  /// The last add wrote nothing: the banner shows and the button reads
  /// "Try again" (`addFailed`).
  final bool hasFailed;
}

/// An add that closes the sheet; the screen toasts it.
sealed class StarterAddResult {
  const StarterAddResult();
}

/// `added`: the copy is in the library; Open goes to [deck]'s root.
final class StarterAdded extends StarterAddResult {
  const StarterAdded(this.deck);

  final AddedStarterDeck deck;
}

/// `alreadyPresent`: a copy was there already and nothing was copied.
final class StarterAlreadyPresent extends StarterAddResult {
  const StarterAlreadyPresent();
}

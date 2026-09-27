import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';

/// Where the decks of a Trash selection may go back (BR-TRASH-006).
sealed class DeckRestoreTargets {
  const DeckRestoreTargets();
}

/// Every deck of the selection is a root: the top level is its one place,
/// which the person still confirms.
final class DeckRestoreTopLevel extends DeckRestoreTargets {
  const DeckRestoreTopLevel();
}

/// Every deck of the selection is a sub-deck: the decks that take all of
/// them, in tree order with their paths, the old parent among them. Empty
/// when none does, or when the selection mixes roots and sub-decks (E1).
final class DeckRestoreUnder extends DeckRestoreTargets {
  const DeckRestoreUnder(this.decks);

  final List<DeckMoveTarget> decks;
}

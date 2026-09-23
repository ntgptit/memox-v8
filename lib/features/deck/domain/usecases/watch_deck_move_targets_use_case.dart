import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-005: the decks the move picker offers, each with its path.
final class WatchDeckMoveTargetsUseCase {
  const WatchDeckMoveTargetsUseCase(this._decks);

  final DeckRepository _decks;

  Stream<List<DeckMoveTarget>> call({required String deckId}) =>
      _decks.watchMoveTargets(deckId);
}

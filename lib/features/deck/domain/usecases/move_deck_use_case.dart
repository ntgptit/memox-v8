import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-005: the deck and its subtree go under [newParentId], at the end
/// of its decks.
final class MoveDeckUseCase {
  const MoveDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({
    required String deckId,
    required String newParentId,
  }) => _decks.moveDeck(deckId: deckId, newParentId: newParentId);
}

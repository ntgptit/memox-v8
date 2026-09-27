import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-002: the deck and its active subtree go to the Trash as one batch
/// (BR-DECK-022, BR-TRASH-001); the batch id is what an Undo takes.
final class DeleteDeckUseCase {
  const DeleteDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<String, DeckRejection>> call({required String deckId}) =>
      _decks.deleteDeck(deckId: deckId);
}

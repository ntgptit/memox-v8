import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-002: the deck and everything below it are gone (BR-DECK-022).
final class DeleteDeckUseCase {
  const DeleteDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({required String deckId}) =>
      _decks.deleteDeck(deckId: deckId);
}

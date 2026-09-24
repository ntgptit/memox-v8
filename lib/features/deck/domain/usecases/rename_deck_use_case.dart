import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-002: a new name for a deck (BR-DECK-020).
final class RenameDeckUseCase {
  const RenameDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({
    required String deckId,
    required String name,
  }) => _decks.renameDeck(deckId: deckId, name: name);
}

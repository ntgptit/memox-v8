import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-006: the deck moves just before or after a sibling (BR-SRS-007).
final class ReorderDeckUseCase {
  const ReorderDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
  }) => _decks.reorderDeck(
    deckId: deckId,
    anchorId: anchorId,
    placement: placement,
  );
}

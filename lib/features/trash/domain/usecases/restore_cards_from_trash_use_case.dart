import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-TRASH-001 steps 6-7: the cards of [batchIds] come back into [deckId],
/// all or none (BR-TRASH-006, BR-TRASH-007).
final class RestoreCardsFromTrashUseCase {
  const RestoreCardsFromTrashUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({
    required Set<String> batchIds,
    required String deckId,
  }) => _cards.restoreCards(batchIds: batchIds, deckId: deckId);
}

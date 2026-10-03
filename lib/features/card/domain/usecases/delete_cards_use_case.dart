import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A2, A6: the cards that still exist go to the Trash (BR-CARD-011),
/// each as a batch of its own whose ids come back in `BulkOutcome.batchIds`
/// (BR-TRASH-001).
final class DeleteCardsUseCase {
  const DeleteCardsUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<BulkOutcome, CardRejection>> call({
    required Set<String> cardIds,
  }) => _cards.deleteCards(cardIds: cardIds);
}

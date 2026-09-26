import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A2, A6: the cards go to the Trash, all or none (BR-CARD-011),
/// each as a batch of its own whose id an Undo takes (BR-TRASH-001).
final class DeleteCardsUseCase {
  const DeleteCardsUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<List<String>, CardRejection>> call({
    required Set<String> cardIds,
  }) => _cards.deleteCards(cardIds: cardIds);
}

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A5, A6: the cards go to another deck of the same root, with
/// their learning (BR-CARD-010).
final class MoveCardsUseCase {
  const MoveCardsUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({
    required Set<String> cardIds,
    required String targetDeckId,
  }) => _cards.moveCards(cardIds: cardIds, targetDeckId: targetDeckId);
}

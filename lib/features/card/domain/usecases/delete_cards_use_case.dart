import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A2, A6: the cards and their learning history are gone, all
/// or none (BR-CARD-011).
final class DeleteCardsUseCase {
  const DeleteCardsUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({required Set<String> cardIds}) =>
      _cards.deleteCards(cardIds: cardIds);
}

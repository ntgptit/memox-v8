import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A6, A7: Set flagged or Remove flag on every card given
/// (BR-CARD-011).
final class SetCardsFlaggedUseCase {
  const SetCardsFlaggedUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({
    required Set<String> cardIds,
    required bool isFlagged,
  }) => _cards.setFlagged(cardIds: cardIds, isFlagged: isFlagged);
}

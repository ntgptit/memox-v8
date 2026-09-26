import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// BR-TRASH-008: the card deleted a moment ago goes back into its deck, or
/// the reason it cannot.
final class UndoCardDeletionUseCase {
  const UndoCardDeletionUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({required String batchId}) =>
      _cards.undoCardDeletion(batchId: batchId);
}

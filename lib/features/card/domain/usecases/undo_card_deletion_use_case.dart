import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// BR-TRASH-008: the cards deleted a moment ago go back into their decks, or
/// the reason they cannot.
final class UndoCardDeletionUseCase {
  const UndoCardDeletionUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({required Set<String> batchIds}) =>
      _cards.undoCardDeletion(batchIds: batchIds);
}

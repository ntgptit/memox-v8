import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// BR-TRASH-008: the deck deleted a moment ago goes back where it was, or
/// the reason it cannot.
final class UndoDeckDeletionUseCase {
  const UndoDeckDeletionUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({required String batchId}) =>
      _decks.undoDeckDeletion(batchId: batchId);
}

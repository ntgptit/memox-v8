import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// BR-DECK-023: the decks and cards a delete would take, for the confirmation.
final class GetDeckDeletionSummaryUseCase {
  const GetDeckDeletionSummaryUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<DeckDeletionSummary, DeckRejection>> call({
    required String deckId,
  }) => _decks.deletionSummary(deckId);
}

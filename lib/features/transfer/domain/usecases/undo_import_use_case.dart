import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-TRANSFER-001 step 8 (SP2a 2.25): the cards an import wrote go to the
/// Trash, a batch each, recoverable for 30 days (BR-TRASH-001). A card gone
/// since is skipped (BR-CARD-011). A database failure leaves as the thrown
/// `Failure`.
final class UndoImportUseCase {
  const UndoImportUseCase(this._cards);

  final CardRepository _cards;

  // ponytail: one transaction of a few statements per card (move, close
  // the sessions touching it), awaited by the dialog, with one Trash entry per
  // card (ruling C9). Upgrade path: a chunked or background delete if
  // undoing a 20,000-card import proves slow.
  Future<Outcome<BulkOutcome, CardRejection>> call({
    required Set<String> cardIds,
  }) => _cards.deleteCards(cardIds: cardIds);
}

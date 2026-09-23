import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A1: new content for a card; its learning stays (BR-CARD-005).
final class EditCardUseCase {
  const EditCardUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({
    required String cardId,
    required CardDraft draft,
  }) => _cards.editCard(cardId: cardId, draft: draft);
}

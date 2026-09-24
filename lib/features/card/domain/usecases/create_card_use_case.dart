import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001, UC-DECK-004 card branch: a new card, ready to learn
/// (BR-CARD-004).
final class CreateCardUseCase {
  const CreateCardUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<CardEntity, CardRejection>> call({
    required String deckId,
    required CardDraft draft,
  }) => _cards.createCard(deckId: deckId, draft: draft);
}

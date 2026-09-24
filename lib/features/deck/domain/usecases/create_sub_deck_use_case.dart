import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-004, deck branch: a new deck at the end of [parentId]'s decks.
final class CreateSubDeckUseCase {
  const CreateSubDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<DeckEntity, DeckRejection>> call({
    required String parentId,
    required String name,
  }) => _decks.createSubDeck(parentId: parentId, name: name);
}

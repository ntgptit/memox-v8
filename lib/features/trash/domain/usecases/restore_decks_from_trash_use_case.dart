import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-TRASH-001 steps 6-7: the decks of [batchIds] come back under
/// [parentId], or to the top level when it is null, all or none
/// (BR-TRASH-006, BR-TRASH-007).
final class RestoreDecksFromTrashUseCase {
  const RestoreDecksFromTrashUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({
    required Set<String> batchIds,
    required String? parentId,
  }) => _decks.restoreDecks(batchIds: batchIds, parentId: parentId);
}

import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-TRASH-001 step 5: where the decks of [batchIds] may go back, again on
/// every change (BR-TRASH-006, E1, E2).
final class WatchDeckRestoreTargetsUseCase {
  const WatchDeckRestoreTargetsUseCase(this._decks);

  final DeckRepository _decks;

  Stream<DeckRestoreTargets> call({required Set<String> batchIds}) =>
      _decks.watchRestoreTargets(batchIds);
}

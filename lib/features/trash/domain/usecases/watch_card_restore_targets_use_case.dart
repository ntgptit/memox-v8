import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-TRASH-001 step 5: where the cards of [batchIds] may go back, again on
/// every change (BR-TRASH-006, E1, E2).
final class WatchCardRestoreTargetsUseCase {
  const WatchCardRestoreTargetsUseCase(this._cards);

  final CardRepository _cards;

  Stream<List<CardMoveTarget>> call({required Set<String> batchIds}) =>
      _cards.watchRestoreTargets(batchIds);
}

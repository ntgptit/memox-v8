import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A5: the decks the Move picker offers, each with its path.
final class WatchCardMoveTargetsUseCase {
  const WatchCardMoveTargetsUseCase(this._cards);

  final CardRepository _cards;

  Stream<List<CardMoveTarget>> call({required String sourceDeckId}) =>
      _cards.watchMoveTargets(sourceDeckId);
}

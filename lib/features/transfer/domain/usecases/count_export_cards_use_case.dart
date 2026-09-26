import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';

/// UC-TRANSFER-002 step 1: how many cards a whole-deck export holds, read
/// before its sheet opens so the sheet itself never loads. 0 opens the
/// sheet on "nothing to export" (E5).
final class CountExportCardsUseCase {
  const CountExportCardsUseCase(this._cards);

  final CardTransferRepository _cards;

  Future<int> call(String deckId) => _cards.countCards(deckId);
}

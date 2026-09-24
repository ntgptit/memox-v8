import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// BR-CARD-015…018: one page of a card's history after [cursor], the newest
/// page without one; notFound when the card is gone.
final class LoadCardHistoryPageUseCase {
  const LoadCardHistoryPageUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<ReviewHistoryPage, CardRejection>> call({
    required String cardId,
    ReviewHistoryCursor? cursor,
  }) async {
    final page = await _cards.historyPage(cardId: cardId, after: cursor);
    if (page == null) return const Rejected(CardRejection.notFound);
    return Ok(page);
  }
}

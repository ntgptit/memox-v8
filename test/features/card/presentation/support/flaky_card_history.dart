import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// Fails the first request for an older page, then answers as [_cards]
/// does; records every cursor it was asked from.
final class FlakyCardHistory implements CardRepository {
  FlakyCardHistory(this._cards);

  final CardRepository _cards;
  final afters = <ReviewHistoryCursor?>[];
  var _hasFailed = false;

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) async {
    afters.add(after);
    if (after != null && !_hasFailed) {
      _hasFailed = true;
      throw const UnknownDatabaseFailure(cause: '/data/memox.sqlite');
    }
    return _cards.historyPage(cardId: cardId, after: after);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

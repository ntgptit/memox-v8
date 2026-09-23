import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-002: a card's detail, again on every change, and notFound once
/// the card is gone (BR-CARD-019). It writes nothing (BR-CARD-013).
final class WatchCardDetailUseCase {
  const WatchCardDetailUseCase(this._cards);

  final CardRepository _cards;

  Stream<Outcome<CardDetail, CardRejection>> call({required String cardId}) =>
      _cards
          .watchDetail(cardId)
          .map<Outcome<CardDetail, CardRejection>>(
            (detail) => switch (detail) {
              final CardDetail detail => Ok(detail),
              null => const Rejected(CardRejection.notFound),
            },
          );
}

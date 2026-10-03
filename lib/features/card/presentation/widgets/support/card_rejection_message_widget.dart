import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Every card of a bulk action over [count] was already gone (SP2a 2.19).
bool isBulkAllGone(CardRejection reason, int count) =>
    reason == CardRejection.notFound && count > 1;

/// Plain copy for every reason the card feature refuses a write (spec §5).
extension CardRejectionMessage on AppLocalizations {
  String cardRejection(CardRejection reason) => switch (reason) {
    CardRejection.blankContent => cardRejectionBlankContent,
    CardRejection.notACardContainer => cardRejectionNotACardContainer,
    CardRejection.notFound => cardRejectionNotFound,
    CardRejection.frontTooLong => cardRejectionFrontTooLong,
    CardRejection.backTooLong => cardRejectionBackTooLong,
    CardRejection.optionalFieldTooLong => cardRejectionOptionalFieldTooLong,
    CardRejection.invalidTagName => cardRejectionInvalidTagName,
    CardRejection.tooManyTags => cardRejectionTooManyTags,
    CardRejection.targetNotFound => cardRejectionTargetNotFound,
    CardRejection.targetIsRoot => cardRejectionTargetIsRoot,
    CardRejection.targetHoldsDecks => cardRejectionTargetHoldsDecks,
    CardRejection.sameDeck => cardRejectionSameDeck,
    CardRejection.crossRootMove => cardRejectionCrossRootMove,
    CardRejection.targetInTrash => cardRejectionTargetInTrash,
    CardRejection.changedElsewhere => cardRejectionChangedElsewhere,
  };

  /// A bulk action's refusal over [count] cards: when every one was already
  /// gone it says how many, instead of the one-card copy (SP2a 2.19).
  String cardBulkRejection(CardRejection reason, int count) =>
      isBulkAllGone(reason, count)
      ? cardBulkAllGone(count)
      : cardRejection(reason);
}

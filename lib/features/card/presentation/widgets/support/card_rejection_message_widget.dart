import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

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
  };
}

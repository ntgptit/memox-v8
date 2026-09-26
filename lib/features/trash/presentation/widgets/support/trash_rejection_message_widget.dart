import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for a refused restore (UC-TRASH-001 E2). The trash feature
/// may not reach into `card` or `deck` presentation, so it maps their
/// reasons itself, to the same messages. Exhaustive with no default, so a
/// new reason fails to compile until it has copy.
extension TrashRejectionMessage on AppLocalizations {
  String trashCardRejection(CardRejection reason) => switch (reason) {
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

  String trashDeckRejection(DeckRejection reason) => switch (reason) {
    DeckRejection.blankName => deckRejectionBlankName,
    DeckRejection.nameTooLong => deckRejectionNameTooLong,
    DeckRejection.depthExceeded => deckRejectionDepthExceeded,
    DeckRejection.notADeckContainer => deckRejectionNotADeckContainer,
    DeckRejection.notACardContainer => deckRejectionNotACardContainer,
    DeckRejection.subtreeSchedulerMismatch =>
      deckRejectionSubtreeSchedulerMismatch,
    DeckRejection.movingIntoOwnSubtree => deckRejectionMovingIntoOwnSubtree,
    DeckRejection.rootCannotMove => deckRejectionRootCannotMove,
    DeckRejection.notFound => deckRejectionNotFound,
    DeckRejection.notSiblings => deckRejectionNotSiblings,
    DeckRejection.sameParent => deckRejectionSameParent,
    DeckRejection.targetNotFound => deckRejectionTargetNotFound,
    DeckRejection.targetInTrash => deckRejectionTargetInTrash,
    DeckRejection.rootRestoresToTopLevel => deckRejectionRootRestoresToTopLevel,
    DeckRejection.subDeckNeedsParent => deckRejectionSubDeckNeedsParent,
  };
}

import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for every reason the deck feature refuses a write (BR-CORE-005).
/// Exhaustive with no default, so a new reason fails to compile until it has
/// copy.
extension DeckRejectionMessage on AppLocalizations {
  String deckRejection(DeckRejection reason) => switch (reason) {
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
  };
}

import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// Names of the card list's filters, sorts and statuses.
extension CardListLabel on AppLocalizations {
  String cardFilter(CardListFilter filter) => switch (filter) {
    CardListFilter.all => cardFilterAll,
    CardListFilter.due => cardFilterDue,
    CardListFilter.newCards => cardFilterNew,
    CardListFilter.flagged => cardFilterFlagged,
  };

  String cardSort(CardListSort sort) => switch (sort) {
    CardListSort.newest => cardSortNewest,
    CardListSort.dueFirst => cardSortDueFirst,
  };

  String cardStatus(CardDisplayStatus status) => switch (status) {
    CardDisplayStatus.newCard => cardStatusNew,
    CardDisplayStatus.beginning => cardStatusBeginning,
    CardDisplayStatus.reviewing => cardStatusReviewing,
    CardDisplayStatus.mastered => cardStatusMastered,
  };
}

/// The badge colour of each display status (BR-CARD-006).
MxCardStatus mxCardStatus(CardDisplayStatus status) => switch (status) {
  CardDisplayStatus.newCard => MxCardStatus.newCard,
  CardDisplayStatus.beginning => MxCardStatus.learning,
  CardDisplayStatus.reviewing => MxCardStatus.reviewing,
  CardDisplayStatus.mastered => MxCardStatus.mastered,
};

/// The count a filter chip shows (IT-ORG-005).
extension CardListCountOf on CardListCounts {
  int of(CardListFilter filter) => switch (filter) {
    CardListFilter.all => all,
    CardListFilter.due => due,
    CardListFilter.newCards => newCards,
    CardListFilter.flagged => flagged,
  };
}

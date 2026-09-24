import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Names of the Library's sort orders.
extension DeckLevelQueryLabel on AppLocalizations {
  String deckSort(DeckLevelSort sort) => switch (sort) {
    DeckLevelSort.manual => deckSortManual,
    DeckLevelSort.name => deckSortName,
    DeckLevelSort.recent => deckSortRecent,
    DeckLevelSort.due => deckSortDue,
  };
}

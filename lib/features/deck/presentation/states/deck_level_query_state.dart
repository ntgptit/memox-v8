import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_level_query_state.g.dart';

/// What the person asked the Library level for: its order and which decks
/// show (UC-DECK-003, UC-DECK-006).
final class DeckLevelQueryState {
  const DeckLevelQueryState({
    this.sort = DeckLevelSort.manual,
    this.filter = DeckLevelFilter.all,
  });

  final DeckLevelSort sort;
  final DeckLevelFilter filter;
}

/// The Library level's query, kept while the screen lives.
@riverpod
class DeckLevelQuery extends _$DeckLevelQuery {
  @override
  DeckLevelQueryState build() => const DeckLevelQueryState();

  void sortBy(DeckLevelSort sort) =>
      state = DeckLevelQueryState(sort: sort, filter: state.filter);

  void show(DeckLevelFilter filter) =>
      state = DeckLevelQueryState(sort: state.sort, filter: filter);
}

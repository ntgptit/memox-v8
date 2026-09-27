import 'package:flutter/foundation.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_list_request_state.g.dart';

/// The cards the list asks for first, and how many more each growth adds
/// (ruling P3-L5).
const int cardListWindowStep = 50;

/// The tags a card list is filtered by (UC-TAG-001 step 7), equal by value
/// so the list's provider is found again: a family key needs `==`.
@immutable
final class CardTagFilter {
  const CardTagFilter([this.ids = const {}]);

  /// A card passes when it carries any of them; none lets every card
  /// through (BR-TAG-004).
  final Set<String> ids;

  bool get isEmpty => ids.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is CardTagFilter && setEquals(other.ids, ids);

  @override
  int get hashCode => Object.hashAllUnordered(ids);
}

/// What the person asked a deck's card list for, and how far it has grown.
final class CardListRequestState {
  const CardListRequestState({
    this.filter = CardListFilter.all,
    this.sort = CardListSort.newest,
    this.searchTerm = '',
    this.tags = const CardTagFilter(),
    this.windowSize = cardListWindowStep,
  });

  final CardListFilter filter;
  final CardListSort sort;
  final String searchTerm;
  final CardTagFilter tags;
  final int windowSize;

  /// The query the list, its counts and Select all share (BR-CARD-012).
  CardListQuery get query => CardListQuery(
    filter: filter,
    sort: sort,
    searchTerm: searchTerm,
    tagIds: tags.ids,
  );
}

/// A deck's card list request, kept while its screen lives. A new filter,
/// sort, term or tag set starts again from the first window.
@riverpod
class CardListRequest extends _$CardListRequest {
  @override
  CardListRequestState build(String deckId) => const CardListRequestState();

  void show(CardListFilter filter) => state = CardListRequestState(
    filter: filter,
    sort: state.sort,
    searchTerm: state.searchTerm,
    tags: state.tags,
  );

  void sortBy(CardListSort sort) => state = CardListRequestState(
    filter: state.filter,
    sort: sort,
    searchTerm: state.searchTerm,
    tags: state.tags,
  );

  void search(String term) => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
    searchTerm: term,
    tags: state.tags,
  );

  /// The list neared its end while more cards follow.
  void grow() => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
    searchTerm: state.searchTerm,
    tags: state.tags,
    windowSize: state.windowSize + cardListWindowStep,
  );

  /// The tags applied from the filter sheet; none is no tag filter (A4).
  void filterTags(Set<String> tagIds) => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
    searchTerm: state.searchTerm,
    tags: CardTagFilter(tagIds),
  );
}

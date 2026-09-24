import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_list_request_state.g.dart';

/// The cards the list asks for first, and how many more each growth adds
/// (ruling P3-L5).
const int cardListWindowStep = 50;

/// What the person asked a deck's card list for, and how far it has grown.
final class CardListRequestState {
  const CardListRequestState({
    this.filter = CardListFilter.all,
    this.sort = CardListSort.newest,
    this.searchTerm = '',
    this.windowSize = cardListWindowStep,
  });

  final CardListFilter filter;
  final CardListSort sort;
  final String searchTerm;
  final int windowSize;

  /// The query the list, its counts and Select all share (BR-CARD-012).
  CardListQuery get query =>
      CardListQuery(filter: filter, sort: sort, searchTerm: searchTerm);
}

/// A deck's card list request, kept while its screen lives. A new filter,
/// sort or term starts again from the first window.
@riverpod
class CardListRequest extends _$CardListRequest {
  @override
  CardListRequestState build(String deckId) => const CardListRequestState();

  void show(CardListFilter filter) => state = CardListRequestState(
    filter: filter,
    sort: state.sort,
    searchTerm: state.searchTerm,
  );

  void sortBy(CardListSort sort) => state = CardListRequestState(
    filter: state.filter,
    sort: sort,
    searchTerm: state.searchTerm,
  );

  void search(String term) => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
    searchTerm: term,
  );

  /// The list neared its end while more cards follow.
  void grow() => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
    searchTerm: state.searchTerm,
    windowSize: state.windowSize + cardListWindowStep,
  );
}

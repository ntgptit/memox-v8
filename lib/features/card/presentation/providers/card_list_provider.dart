import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/providers/watch_card_list_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_list_provider.g.dart';

/// A window of [deckId]'s cards and the filter counts (UC-CARD-001), again
/// on every change and at each local midnight. The query arrives as
/// primitives: `CardListQuery` has no `==`, and a family key needs one.
@riverpod
Stream<CardListView> cardList(
  Ref ref, {
  required String deckId,
  required CardListFilter filter,
  required CardListSort sort,
  required String searchTerm,
  required int windowSize,
}) => ref.watch(watchCardListUseCaseProvider)(
  deckId: deckId,
  query: CardListQuery(filter: filter, sort: sort, searchTerm: searchTerm),
  windowSize: windowSize,
);

import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/watch_deck_level_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_level_provider.g.dart';

/// A level of the deck tree with its counts, the roots when [parentId] is
/// null (UC-DECK-003). It emits again on every change and at each local
/// midnight.
@riverpod
Stream<DeckLevel> deckLevel(
  Ref ref, {
  required DeckLevelSort sort,
  required DeckLevelFilter filter,
  String? parentId,
}) => ref.watch(watchDeckLevelUseCaseProvider)(
  parentId: parentId,
  sort: sort,
  filter: filter,
);

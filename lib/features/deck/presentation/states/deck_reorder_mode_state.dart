import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_reorder_mode_state.g.dart';

/// Whether a level is in drag-to-reorder mode (spec §6.1, ruling P2-L3).
@riverpod
class DeckReorderMode extends _$DeckReorderMode {
  @override
  bool build(String? parentId) => false;

  void start() => state = true;

  void finish() => state = false;
}

/// Fewer decks than this have no order to change.
const int _minReorderableDecks = 2;

/// Whether a level may enter reorder mode now (ruling P2-L3).
@riverpod
bool deckLevelCanReorder(Ref ref, String? parentId) {
  final query = ref.watch(deckLevelQueryProvider(parentId));
  if (!query.allowsReorder) return false;
  final level = ref
      .watch(
        deckLevelProvider(
          parentId: parentId,
          sort: query.sort,
          filter: query.filter,
        ),
      )
      .value;
  return (level?.tiles.length ?? 0) >= _minReorderableDecks;
}

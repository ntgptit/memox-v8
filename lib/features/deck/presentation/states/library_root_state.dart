import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_root_state.g.dart';

/// The Library root as one state for its chrome and its body (screen 01):
/// the search trigger, Tags and the FAB exist only with decks (The Content
/// Gate Rule, DESIGN.md); Starter decks and the Trash always do. Loading
/// and failure count as no content.
sealed class LibraryRootState {
  const LibraryRootState();

  bool get hasDecks => this is LibraryRootDecks;
}

final class LibraryRootLoading extends LibraryRootState {
  const LibraryRootLoading();
}

final class LibraryRootFailed extends LibraryRootState {
  const LibraryRootFailed();
}

/// The level holds no deck: the first run (ruling L4).
final class LibraryRootEmpty extends LibraryRootState {
  const LibraryRootEmpty();
}

final class LibraryRootDecks extends LibraryRootState {
  const LibraryRootDecks(this.level);

  final DeckLevel level;
}

/// Derived from the same level stream the body reads, so both change in
/// one frame. A refresh that still has data keeps its state; a failure is
/// Failed even over a stale value, as the body's error state is.
@riverpod
LibraryRootState libraryRootState(Ref ref) {
  final query = ref.watch(deckLevelQueryProvider(null));
  final level = ref.watch(
    deckLevelProvider(parentId: null, sort: query.sort, filter: query.filter),
  );
  // Object patterns on the getters: a refresh keeps its previous value
  // (hasValue), a failure over a stale value is still an error.
  return switch (level) {
    AsyncValue(hasError: true) => const LibraryRootFailed(),
    AsyncValue(hasValue: true, :final value?) =>
      value.hasDecks ? LibraryRootDecks(value) : const LibraryRootEmpty(),
    _ => const LibraryRootLoading(),
  };
}

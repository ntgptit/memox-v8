import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// IT-DISC-006, IT-DISC-007: the decks below [scopeDeckId] (all decks when it
/// is null) whose name holds [term], case and surrounding spaces aside. A
/// blank term searches nothing.
final class SearchDecksUseCase {
  const SearchDecksUseCase(this._decks);

  final DeckRepository _decks;

  Stream<List<DeckSearchHit>> call({
    required String? scopeDeckId,
    required String term,
  }) {
    final foldedTerm = foldText(term);
    if (foldedTerm.isEmpty) return Stream.value(const <DeckSearchHit>[]);
    return _decks.watchSearch(scopeDeckId: scopeDeckId, foldedTerm: foldedTerm);
  }
}

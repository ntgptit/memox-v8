import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';

/// UC-SEARCH-001: the decks and cards whose searched fields hold [term],
/// case and the spaces around it aside, through [through] (the first page
/// when it is null), again after every write they can see. A blank term is
/// [LibrarySearchIdle] and reads nothing (BR-SEARCH-002, BR-SEARCH-003).
final class SearchLibraryUseCase {
  const SearchLibraryUseCase(this._search);

  final SearchRepository _search;

  Stream<LibrarySearch> call({required String term, SearchCursor? through}) {
    final foldedTerm = foldText(term);
    if (foldedTerm.isEmpty) return Stream.value(const LibrarySearchIdle());
    return _search.watchSearch(foldedTerm: foldedTerm, through: through);
  }
}

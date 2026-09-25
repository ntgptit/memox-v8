import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

/// The library search's read (UC-SEARCH-001). The one implementation is
/// `SearchRepositoryImpl` (data layer); the contract exists for ADR-010's
/// reason: domain stays framework-free and tests substitute a fake.
abstract interface class SearchRepository {
  /// The hits of [foldedTerm], a term folded with `foldText`, from the first
  /// through [through], or the first page when it is null (Search spec
  /// §5.4), decks first, with the cursor that ends the next page; again
  /// after every write it can see. It writes nothing (BR-SEARCH-008).
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  });
}

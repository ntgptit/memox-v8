import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/search/data/datasources/search_dao.dart';
import 'package:memox/features/search/data/mappers/search_mapper.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';

/// Reads the library search (UC-SEARCH-001; Search spec §6): one snapshot in
/// one transaction, once when listened to and again after every write it
/// can see.
final class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._db) : _search = SearchDao(_db);

  final AppDatabase _db;
  final SearchDao _search;

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => _search
      .changes()
      .asyncMap((_) => _db.transaction(() => _read(foldedTerm, through)))
      .mapDatabaseErrors();

  /// The hits through [through], or the first page when it is null or when
  /// nothing through it is left, and the cursor that ends the next page
  /// (Search spec §5.4).
  Future<LibrarySearchResults> _read(String term, SearchCursor? through) async {
    final rows = await _search.deckForest();
    final decks = deckHitsOf(searchableDecksOf(rows, trailsOf(rows)), term);
    final bounded = through == null
        ? const <SearchDeckHit>[]
        : [
            for (final hit in decks)
              if (hit.cursor.compareTo(through) <= 0) hit,
          ];
    final shown = bounded.isEmpty
        ? decks.take(searchPageSize).toList()
        : bounded;
    final next = shown.isEmpty
        ? const <SearchDeckHit>[]
        : [
            for (final hit in decks)
              if (hit.cursor.compareTo(shown.last.cursor) > 0) hit,
          ].take(searchPageSize).toList();
    return LibrarySearchResults(
      decks: shown,
      cards: const [],
      nextThrough: next.isEmpty ? null : next.last.cursor,
    );
  }
}

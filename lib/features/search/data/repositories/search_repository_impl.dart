import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
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
  /// (Search spec §5.4, §6.3).
  Future<LibrarySearchResults> _read(String term, SearchCursor? through) async {
    final rows = await _search.deckForest();
    final trails = trailsOf(rows);
    final decks = deckHitsOf(searchableDecksOf(rows, trails), term);
    Future<_Page> pageAfter(SearchCursor? cursor) =>
        _pageAfter(term, decks, trails, cursor);
    final bounded = through == null
        ? _Page.none
        : await _through(term, decks, trails, through);
    final shown = bounded.isEmpty ? await pageAfter(null) : bounded;
    final next = shown.isEmpty ? _Page.none : await pageAfter(shown.last);
    return LibrarySearchResults(
      decks: shown.decks,
      cards: shown.cards,
      nextThrough: next.isEmpty ? null : next.last,
    );
  }

  /// The hits at or before [through]: the decks, and the cards when it is a
  /// card's cursor.
  Future<_Page> _through(
    String term,
    List<SearchDeckHit> decks,
    Map<String, List<DeckPathEntry>> trails,
    SearchCursor through,
  ) async => _Page(
    [
      for (final hit in decks)
        if (hit.cursor.compareTo(through) <= 0) hit,
    ],
    through.group == SearchGroup.deck
        ? const []
        : cardHitsOf(
            await _search.cardHits(term: term, through: through),
            trails,
          ),
  );

  /// One page after [after], the first when it is null: decks first, then
  /// cards to fill it (BR-SEARCH-005).
  Future<_Page> _pageAfter(
    String term,
    List<SearchDeckHit> decks,
    Map<String, List<DeckPathEntry>> trails,
    SearchCursor? after,
  ) async {
    final pageDecks = [
      for (final hit in decks)
        if (after == null || hit.cursor.compareTo(after) > 0) hit,
    ].take(searchPageSize).toList();
    final room = searchPageSize - pageDecks.length;
    if (room == 0) return _Page(pageDecks, const []);
    final cards = await _search.cardHits(
      term: term,
      after: after?.group == SearchGroup.card ? after : null,
      limit: room,
    );
    return _Page(pageDecks, cardHitsOf(cards, trails));
  }
}

/// Hits in order, decks first (BR-SEARCH-005).
final class _Page {
  const _Page(this.decks, this.cards);

  static const none = _Page([], []);

  final List<SearchDeckHit> decks;
  final List<SearchCardHit> cards;

  bool get isEmpty => decks.isEmpty && cards.isEmpty;

  /// The cursor of the last hit, of a page that is not empty.
  SearchCursor get last =>
      cards.isEmpty ? decks.last.cursor : cards.last.cursor;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';

// BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-004: the decks a term finds, in
// the deck group's order (Search spec §5.2, §5.3, §6.1).

SearchableDeck _deck(String id, String name, {DateTime? createdAt}) =>
    SearchableDeck(
      deckId: id,
      name: name,
      createdAt: createdAt ?? DateTime.utc(2026, 9),
      path: const [DeckPathEntry(id: 'root', name: 'Root')],
      contentType: DeckContentType.card,
    );

List<String> _ids(List<SearchDeckHit> hits) => [
  for (final hit in hits) hit.deckId,
];

void main() {
  test('a name is folded in Dart: công nghệ finds CÔNG NGHỆ, and cong nghe '
      'is not found, accents counting (BR-SEARCH-002)', () {
    final decks = [_deck('upper', 'CÔNG NGHỆ'), _deck('plain', 'Cong nghe')];

    expect(_ids(deckHitsOf(decks, 'công nghệ')), ['upper']);
  });

  test('the exact name first, then the names it begins, then the names that '
      'hold it; the others are not hits (BR-SEARCH-001, BR-SEARCH-004)', () {
    final hits = deckHitsOf([
      _deck('contains', 'Từ vựng học thuật'),
      _deck('prefix', 'Học qua phim'),
      _deck('exact', 'Học'),
      _deck('none', 'Ngữ pháp'),
    ], 'học');

    expect(_ids(hits), ['exact', 'prefix', 'contains']);
    expect(
      [for (final hit in hits) hit.tier],
      [SearchTier.exact, SearchTier.prefix, SearchTier.contains],
    );
  });

  test('a tie falls to the folded name, then created_at, then the id, in the '
      'same order whatever order the decks come in (BR-SEARCH-004, '
      'BR-SEARCH-007)', () {
    final decks = [
      _deck('b', 'Học B'),
      _deck('late', 'Học A', createdAt: DateTime.utc(2026, 9, 3)),
      _deck('a2', 'học a', createdAt: DateTime.utc(2026, 9, 2)),
      _deck('a1', 'HỌC A', createdAt: DateTime.utc(2026, 9, 2)),
    ];

    final once = _ids(deckHitsOf(decks, 'học'));

    expect(once, ['a1', 'a2', 'late', 'b']);
    expect(_ids(deckHitsOf(decks.reversed, 'học')), once);
  });

  test('a hit shows the deck as written, with its path and content type; it '
      'sorts in the deck group on its folded name (Search spec §5.1)', () {
    final hit = deckHitsOf([_deck('d', 'Học qua phim')], 'học').single;

    expect(hit.name, 'Học qua phim');
    expect([for (final step in hit.path) step.name], ['Root']);
    expect(hit.contentType, DeckContentType.card);
    expect(
      (hit.cursor.group, hit.cursor.sortText),
      (SearchGroup.deck, 'học qua phim'),
    );
  });

  test('results with neither a deck nor a card have nothing to show '
      '(UC-SEARCH-001, no results)', () {
    const none = LibrarySearchResults(decks: [], cards: [], nextThrough: null);
    final one = LibrarySearchResults(
      decks: deckHitsOf([_deck('d', 'Học')], 'học'),
      cards: const [],
      nextThrough: null,
    );

    expect(none.hasResults, isFalse);
    expect(one.hasResults, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

// BR-SEARCH-004, BR-SEARCH-005, BR-SEARCH-007: the tier of a match and the
// total order of the results (Search spec §5.2, §5.3).

SearchCursor _cursor({
  SearchGroup group = SearchGroup.deck,
  SearchTier tier = SearchTier.exact,
  String sortText = 'a',
  DateTime? createdAt,
  String id = 'id',
}) => SearchCursor(
  group: group,
  tier: tier,
  sortText: sortText,
  createdAt: createdAt ?? DateTime.utc(2026, 9),
  id: id,
);

void main() {
  test('a folded text holds a folded term exactly, as a prefix, inside it, '
      'or not at all; accents count (BR-SEARCH-002, BR-SEARCH-004)', () {
    expect(searchTierOf('học', 'học'), SearchTier.exact);
    expect(searchTierOf('học qua phim', 'học'), SearchTier.prefix);
    expect(searchTierOf('từ vựng học thuật', 'học'), SearchTier.contains);
    expect(searchTierOf('hoc qua phim', 'học'), isNull);
  });

  test('every deck comes before every card, whatever its tier and text '
      '(BR-SEARCH-005)', () {
    final deck = _cursor(tier: SearchTier.contains, sortText: 'z');
    final card = _cursor(group: SearchGroup.card, sortText: 'a');

    expect(deck.compareTo(card), lessThan(0));
    expect(card.compareTo(deck), greaterThan(0));
  });

  test('within a group the tier comes first, then the text, then created_at, '
      'then the id: no two rows are equal (BR-SEARCH-004, BR-SEARCH-007)', () {
    final later = DateTime.utc(2026, 9, 2);
    final ordered = [
      _cursor(sortText: 'z'),
      _cursor(tier: SearchTier.prefix),
      _cursor(tier: SearchTier.prefix, sortText: 'b'),
      _cursor(tier: SearchTier.prefix, sortText: 'b', createdAt: later),
      _cursor(
        tier: SearchTier.prefix,
        sortText: 'b',
        createdAt: later,
        id: 'id2',
      ),
    ];

    final sorted = [...ordered.reversed]..sort();

    expect(sorted, ordered);
    expect(ordered.last.compareTo(ordered.last), 0);
  });

  test('texts compare by code point, the order SQLite gives UTF-8: a '
      'halfwidth ｱ comes before 𝒜, where Dart strings put it after '
      '(Search spec D5)', () {
    expect(
      _cursor(sortText: 'ｱ').compareTo(_cursor(sortText: '𝒜')),
      lessThan(0),
    );
    expect('ｱ'.compareTo('𝒜'), greaterThan(0));
    expect(_cursor(sortText: 'ab').compareTo(_cursor(sortText: 'a')), 1);
  });
}

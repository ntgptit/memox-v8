import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_search_match_widget.dart';

void main() {
  test('finds the term whatever its case, and keeps the name’s letters', () {
    expect(deckSearchMatch('Ăn uống', 'ĂN'), (0, 2));
    expect(deckSearchMatch('Academic words', 'words'), (9, 14));
  });

  test('accents matter: "hoc" does not match "học"', () {
    expect(deckSearchMatch('Học qua phim', 'hoc'), isNull);
  });

  test('a blank term matches nothing', () {
    expect(deckSearchMatch('Korean', '  '), isNull);
  });

  test('the term is trimmed but the name is not', () {
    expect(deckSearchMatch('  Korean', ' korean '), (2, 8));
  });
}

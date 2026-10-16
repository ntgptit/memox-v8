import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/meta_line.dart';

// DESIGN.md, The Wrap Rule: a meta line that wraps does so only between
// whole terms (owner, Q-P6-4).
void main() {
  test('a term keeps its spaces and its range dash from breaking', () {
    expect(wholeTerm('Levels 3–6'), 'Levels\u00A03\u2060–\u20606');
  });

  test('terms join with the dot glued to the term before it', () {
    expect(
      metaTerms(['4 sub-decks', '1,248 cards']),
      '4\u00A0sub-decks\u00A0· 1,248\u00A0cards',
    );
  });

  test('a line already joined with " · " is split there and glued', () {
    expect(
      metaLine('Sep 24 09:00 · 1h 27m 00s'),
      'Sep\u00A024\u00A009:00\u00A0· 1h\u00A027m\u00A000s',
    );
  });

  test('one term is glued, with no separator', () {
    expect(metaLine('420 cards'), '420\u00A0cards');
  });
}

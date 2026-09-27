import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/folded_text.dart';

void main() {
  test('folding trims, then lowercases beyond ASCII', () {
    expect(foldText('  Ăn Uống  '), 'ăn uống');
    expect(foldText('ÉCOLE'), 'école');
  });

  test('folding gives one form for precomposed and decomposed text, '
      'Vietnamese and Hangul alike (BE-C5)', () {
    expect(foldText('  CO\u0302NG '), foldText('c\u00F4ng'));
    expect(foldText('CO\u0302NG'), 'c\u00F4ng');
    expect(foldText('\u1107\u1161\u11B8'), '\uBC25');
    expect(foldText('E\u0323\u0302'), '\u1EC7'); // Ệ decomposed → ệ
  });
}

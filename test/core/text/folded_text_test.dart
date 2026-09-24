import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/folded_text.dart';

void main() {
  test('folding trims, then lowercases beyond ASCII', () {
    expect(foldText('  Ăn Uống  '), 'ăn uống');
    expect(foldText('ÉCOLE'), 'école');
  });
}

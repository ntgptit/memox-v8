import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/meta_line.dart';

// DESIGN.md, The Wrap Rule: the glue a plain text keeps. Lines of terms are
// MxTermLine's (spec W1).
void main() {
  test('a line of phrases keeps its words breakable, each dot glued to the '
      'phrase before it (spec W2)', () {
    expect(
      metaDots('Empty · add cards or a sub-deck'),
      'Empty · add cards or a sub-deck',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/path_label.dart';

void main() {
  test('a path reads root first, joined by the separator', () {
    expect(pathLabel(['Korean', 'Words']), 'Korean › Words');
    expect(pathLabel(const []), '');
  });
}

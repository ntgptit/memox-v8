import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/id/new_id.dart';

void main() {
  test('newId returns a v4 UUID and two calls differ', () {
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final a = newId();
    final b = newId();
    expect(a, isNot(equals(b)));
    expect(a, matches(uuidV4));
    expect(b, matches(uuidV4));
  });
}

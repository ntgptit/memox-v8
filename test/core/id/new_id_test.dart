import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/id/new_id.dart';

// ADR-007: a client-generated UUID, version 7 so that ids written in one
// batch sort in the order they were made (DEV-216).

void main() {
  final uuidV7 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('newId returns a v7 UUID and two calls differ', () {
    final a = newId();
    final b = newId();
    expect(a, isNot(equals(b)));
    expect(a, matches(uuidV7));
    expect(b, matches(uuidV7));
  });

  test('ids made back to back sort in the order they were made', () {
    // Far more than one millisecond holds, so most pairs share a timestamp.
    final ids = List.generate(5000, (_) => newId());
    for (var i = 1; i < ids.length; i++) {
      expect(
        ids[i].compareTo(ids[i - 1]),
        greaterThan(0),
        reason: 'id $i must sort after id ${i - 1}',
      );
    }
    expect(ids.toSet().length, ids.length);
  });
}

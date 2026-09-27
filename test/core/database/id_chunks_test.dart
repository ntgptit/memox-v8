import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/id_chunks.dart';

// BE-C2: an id set larger than SQLite binds goes in chunks (local backend
// spec 2026-09-27 §5).
void main() {
  test('ids go in chunks of at most the size, in their order', () {
    expect(idChunks(['a', 'b', 'c', 'd', 'e'], size: 2), [
      ['a', 'b'],
      ['c', 'd'],
      ['e'],
    ]);
  });

  test('an empty set is no chunk, so no statement runs', () {
    expect(idChunks(<String>[]), isEmpty);
  });

  test('exactly the default size is one chunk; one more is two', () {
    final ids = [for (var i = 0; i < sqliteIdChunk + 1; i++) '$i'];
    expect(idChunks(ids.take(sqliteIdChunk)), hasLength(1));
    expect(idChunks(ids).map((chunk) => chunk.length), [sqliteIdChunk, 1]);
  });

  test("the default stays under SQLite's bind limit with room to spare", () {
    expect(sqliteIdChunk, lessThan(32766));
  });
}

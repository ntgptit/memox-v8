import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/search_match.dart';

void main() {
  group('searchMatchRange', () {
    test('finds the term case-insensitively, as a range in the text', () {
      expect(searchMatchRange('Ăn uống', 'ĂN'), (0, 2));
      expect(searchMatchRange('Academic words', 'words'), (9, 14));
    });

    test('accents matter (BR-SEARCH-002)', () {
      expect(searchMatchRange('Học qua phim', 'hoc'), isNull);
    });

    test('a blank term marks nothing', () {
      expect(searchMatchRange('Korean', '  '), isNull);
    });

    test('the term is trimmed, the text is not', () {
      expect(searchMatchRange('  Korean', ' korean '), (2, 8));
    });
  });

  group('searchPairMatch (spec D20)', () {
    test('a front match keeps its own range', () {
      expect(searchPairMatch('học sinh', 'student', 'sinh'), (4, 8));
    });

    test('a back match is shifted past the front and the separator', () {
      const front = '학생';
      final offset = front.length + searchFaceSeparator.length;
      expect(searchPairMatch(front, 'học sinh', 'học'), (offset, offset + 3));
    });

    test('the front wins when both faces hold the term', () {
      expect(searchPairMatch('học', 'học tập', 'học'), (0, 3));
    });

    test('neither face: a tag-only hit emphasises nothing', () {
      expect(searchPairMatch('homework', 'bài tập', 'học'), isNull);
    });

    test('the separator itself is never matched', () {
      expect(searchPairMatch('a', 'b', '·'), isNull);
      expect(searchPairMatch('a', 'b', 'a · b'), isNull);
    });
  });
}

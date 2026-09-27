import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/tags_cell_model.dart';

void main() {
  test(
    'tags join with ; and escape ; and \\ inside a tag (BR-TRANSFER-009)',
    () {
      expect(TagsCell.encode(['a', 'b;c', r'd\e']), r'a;b\;c;d\\e');
      expect(TagsCell.encode(const []), '');
    },
  );

  test(
    'decoding restores the spelling and the set of tags (BR-TRANSFER-009)',
    () {
      const tags = ['TOPIK', 'a;b', r'c\d', r'e\;f', 'g h'];
      expect(TagsCell.decode(TagsCell.encode(tags)), tags);
    },
  );

  test('a backslash before another character or at the end stays verbatim', () {
    expect(TagsCell.decode(r'a\b;c\'), [r'a\b', r'c\']);
  });

  test('tags are trimmed and blank ones dropped', () {
    expect(TagsCell.decode(' a ;; b ;'), ['a', 'b']);
    expect(TagsCell.decode('   '), isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/tag_cell_model.dart';

// BR-TRANSFER-009: one codec for the tags cell, import and export alike.

void main() {
  test('names are joined by ";", with ";" and "\\" escaped inside a name', () {
    expect(
      TagCell.encode(['noun', 'a;b', r'c\d', r'e\']),
      r'noun;a\;b;c\\d;e\\',
    );
    expect(TagCell.encode([]), '');
  });

  test(r'decoding splits on each ";" no "\" escapes, and unescapes', () {
    expect(TagCell.decode(r'noun;a\;b;c\\d;e\\'), [
      'noun',
      'a;b',
      r'c\d',
      r'e\',
    ]);
  });

  test(r'a "\" before anything else, or at the end, stays as it is: legacy '
      'sources never escaped', () {
    expect(TagCell.decode(r'a\b;c\'), [r'a\b', r'c\']);
  });

  test('a segment empty after trim is dropped; names keep their spaces', () {
    expect(TagCell.decode('noun;; verb ;'), ['noun', ' verb ']);
    expect(TagCell.decode(''), isEmpty);
    expect(TagCell.decode(' ; '), isEmpty);
  });

  test('a round trip keeps every name and its spelling', () {
    const names = ['Động từ', 'a;b', r'\', r'\;', ';', 'x\\\\y', '명사'];

    expect(TagCell.decode(TagCell.encode(names)), names);
  });
}

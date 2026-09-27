import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

// BR-TAG-003: the catalog's search, on a list already read.

const _tags = [
  TagCount(id: 'a', name: 'động từ', cardCount: 3),
  TagCount(id: 'b', name: 'Học', cardCount: 1),
  TagCount(id: 'c', name: 'ngữ pháp', cardCount: 2),
];

void main() {
  test('a term keeps the tags whose folded name holds its fold, in order', () {
    expect(_tags.matching('ĐỘNG').map((tag) => tag.id), ['a']);
    expect(_tags.matching(' học ').map((tag) => tag.id), ['b']);
    expect(_tags.matching('p').map((tag) => tag.id), ['c']);
  });

  test('accents matter, as the store folds only case', () {
    expect(_tags.matching('hoc'), isEmpty);
  });

  test('a blank term keeps every tag', () {
    expect(_tags.matching('  '), _tags);
  });
}

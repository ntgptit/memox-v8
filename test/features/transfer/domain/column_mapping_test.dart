import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';

// UC-TRANSFER-001 steps 4 and A2, A3: the columns a sheet feeds the card
// fields through (BR-TRANSFER-002; transfer spec D7).

ImportSheet _sheet(List<List<String>> rows) => ImportSheet(
  rows: [
    for (final (index, cells) in rows.indexed)
      ImportRow(number: index + 1, cells: cells),
  ],
);

void main() {
  group('the default mapping', () {
    test('a header maps the six canonical names, trimmed and in any case; '
        'the first column wins', () {
      final mapping = ColumnMapping.byHeader([
        ' Front ',
        'BACK',
        'note',
        'Tags',
        'front',
        'Pronunciation',
      ]);

      expect(mapping.columns, {
        CardField.front: 0,
        CardField.back: 1,
        CardField.tags: 3,
        CardField.pronunciation: 5,
      });
    });

    test('other names, the app labels among them, map nothing', () {
      expect(
        ColumnMapping.byHeader(['term', 'meaning', 'sentence', 'labels'])
            .columns,
        isEmpty,
      );
    });

    test('without a header, column A is the front and B the back', () {
      expect(ColumnMapping.byPosition(0).columns, isEmpty);
      expect(ColumnMapping.byPosition(1).columns, {CardField.front: 0});
      expect(ColumnMapping.byPosition(4).columns, {
        CardField.front: 0,
        CardField.back: 1,
      });
    });
  });

  group('changing the mapping', () {
    const mapping = ColumnMapping({CardField.front: 0, CardField.back: 1});

    test('a field moved to a column leaves its old column, and the column '
        'leaves its old field', () {
      expect(mapping.assign(CardField.back, 0).columns, {CardField.back: 0});
      expect(mapping.assign(CardField.example, 2).columns, {
        CardField.front: 0,
        CardField.back: 1,
        CardField.example: 2,
      });
      expect(mapping.assign(CardField.front, 1).columns, {CardField.front: 1});
    });

    test('a field unassigned reads no column', () {
      expect(mapping.unassign(CardField.back).columns, {CardField.front: 0});
      expect(mapping.fieldAt(1), CardField.back);
      expect(mapping.fieldAt(2), isNull);
      expect(mapping.columnOf(CardField.tags), isNull);
    });

    test('front and back are required', () {
      expect(mapping.missing, isEmpty);
      expect(mapping.unassign(CardField.back).missing, {CardField.back});
      expect(const ColumnMapping().missing, {CardField.front, CardField.back});
    });
  });

  test('a column is named by letters: A…Z, then AA', () {
    expect(
      [
        for (final index in [0, 1, 25, 26, 27, 51, 52, 701, 702])
          columnLetter(index),
      ],
      ['A', 'B', 'Z', 'AA', 'AB', 'AZ', 'BA', 'ZZ', 'AAA'],
    );
  });

  test('a sheet is as wide as its widest row, and empty when every row is '
      'blank', () {
    final sheet = _sheet([
      ['a'],
      ['b', 'c', ' '],
    ]);
    expect(sheet.columnCount, 3);
    expect(sheet.isEmpty, isFalse);
    expect(
      _sheet([
        [' ', '\t'],
        [''],
      ]).isEmpty,
      isTrue,
    );
    expect(_sheet([]).columnCount, 0);
  });

  test('a document opens on its first sheet that is not empty '
      '(UC-TRANSFER-001 A2)', () {
    final empty = _sheet([
      ['  '],
    ]);
    final full = _sheet([
      ['a', 'b'],
    ]);

    expect(ImportDocument([empty, full, empty]).defaultSheetIndex, 1);
    expect(ImportDocument([full]).defaultSheetIndex, 0);
    expect(ImportDocument([empty, empty]).defaultSheetIndex, 0);
  });
}

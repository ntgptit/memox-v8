import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

// BR-TRANSFER-015: a row whose front cell starts with * names a deck.

const _faces = ColumnMapping({0: TransferField.front, 1: TransferField.back});

List<ImportSection>? _split(
  List<List<String>> rows, {
  bool hasHeaderRow = true,
}) => splitSections(
  table: SourceTable(rows: rows),
  mapping: _faces,
  hasHeaderRow: hasHeaderRow,
);

/// Records compare a list by identity, so the indexes are joined.
List<(String, bool, String)> _shape(List<ImportSection> sections) => [
  for (final s in sections) (s.name, s.isDefault, s.rowIndexes.join(',')),
];

void main() {
  test('no section row: a flat source (BR-TRANSFER-015)', () {
    expect(
      _split([
        ['Term', 'Meaning'],
        ['a', 'b'],
      ]),
      isNull,
    );
  });

  test(
    'each * row opens a section; rows before the first go to the default',
    () {
      final sections = _split([
        ['Term', 'Meaning'],
        ['x', 'y'],
        ['*Part 1', '*Part 1'],
        ['가난하다', 'Be poor'],
        ['  *관용어 ', ''],
        ['눈이 높다', 'Standards are high'],
      ])!;
      expect(_shape(sections), [
        ('', true, '1'),
        ('Part 1', false, '3'),
        ('관용어', false, '5'),
      ]);
    },
  );

  test('names that fold equal are one section, kept in source order', () {
    final sections = _split([
      ['Term', 'Meaning'],
      ['*A', ''],
      ['a1', 'x'],
      ['*B', ''],
      ['b1', 'x'],
      ['*a ', ''],
      ['a2', 'x'],
    ])!;
    expect(_shape(sections), [('A', false, '2,6'), ('B', false, '4')]);
  });

  test(
    '* alone is a section with a blank name; ** is a name starting with *',
    () {
      final sections = _split([
        ['Term', 'Meaning'],
        ['*', ''],
        ['a', 'b'],
        ['**x', ''],
        ['c', 'd'],
      ])!;
      expect(_shape(sections), [('', false, '2'), ('*x', false, '4')]);
    },
  );

  test('a header is never a section; without a header row 0 can be', () {
    expect(
      _split([
        ['*Term', 'Meaning'],
        ['a', 'b'],
      ]),
      isNull,
    );
    expect(
      _shape(
        _split([
          ['*Part', ''],
          ['a', 'b'],
        ], hasHeaderRow: false)!,
      ),
      [('Part', false, '1')],
    );
  });

  test('blank rows before the first section make no default deck', () {
    expect(
      _shape(
        _split([
          ['Term', 'Meaning'],
          ['', ''],
          ['*A', ''],
          ['a', 'b'],
        ])!,
      ),
      [('A', false, '3')],
    );
  });

  test('classifyRows measures duplicates within the rows it is given only', () {
    final table = SourceTable(
      rows: [
        ['Term', 'Meaning'],
        ['a', 'b'],
        ['a', 'b'],
        ['c', 'd'],
      ],
    );
    final rows = classifyRows(
      table: table,
      rowIndexes: const [1, 3],
      mapping: _faces,
      existing: {(front: 'c', back: 'd')},
    );
    expect(
      [for (final r in rows) (r.rowNumber, r.kind)],
      [(2, ImportRowKind.ready), (4, ImportRowKind.duplicateInDeck)],
    );
  });
}

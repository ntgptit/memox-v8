import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';

// UC-TRANSFER-001 step 5, E2, E3: every data row's status, by the card's
// own rules and the duplicate key (BR-TRANSFER-002, BR-TRANSFER-003;
// transfer spec §6.2, D8).

ImportSheet _sheet(List<List<String>> rows) => ImportSheet(
  rows: [
    for (final (index, cells) in rows.indexed)
      ImportRow(number: index + 1, cells: cells),
  ],
);

ImportPreview _classify(
  List<List<String>> rows, {
  ImportSettings settings = const ImportSettings(),
  Set<ContentKey> deckKeys = const {},
}) => ImportPreview.classify(
  sheet: _sheet(rows),
  settings: settings,
  deckKeys: deckKeys,
);

/// Each row as `number status`, with what the status names.
List<String> _statuses(ImportPreview preview) => [
  for (final row in preview.rows)
    switch (row) {
      ImportRowReady(:final rowNumber) => '$rowNumber ready',
      ImportRowDuplicate(:final rowNumber, firstRowNumber: null) =>
        '$rowNumber duplicate in the deck',
      ImportRowDuplicate(:final rowNumber, :final firstRowNumber?) =>
        '$rowNumber duplicate of $firstRowNumber',
      ImportRowInvalid(:final rowNumber, :final field, :final reason) =>
        '$rowNumber invalid ${field.name} ${reason.name}',
      ImportRowBlank(:final rowNumber) => '$rowNumber blank',
    },
];

void main() {
  test('every status, in the order the rules run', () {
    final preview = _classify(
      [
        ['front', 'back', 'example'],
        ['reservation', 'sự đặt chỗ trước', ''],
        ['bill', '', ''],
        [' Reservation ', 'Sự đặt chỗ trước', ''],
        ['tip', 'tiền boa', ''],
        ['', '', ''],
        ['TIP', 'Tiền boa ', 'an example'],
        ['a' * 61, 'too long', ''],
        ['menu', 'thực đơn', ''],
      ],
      deckKeys: {('reservation', 'sự đặt chỗ trước')},
    );

    expect(_statuses(preview), [
      '2 duplicate in the deck',
      '3 invalid back blankContent',
      '4 duplicate in the deck',
      '5 ready',
      '6 blank',
      '7 duplicate of 5',
      '8 invalid front frontTooLong',
      '9 ready',
    ]);
    expect(
      (
        preview.readyCount,
        preview.duplicateCount,
        preview.invalidCount,
        preview.blankCount,
        preview.dataRowCount,
      ),
      (2, 3, 2, 1, 7),
    );
    expect(preview.writeCount, 2);
    expect([for (final draft in preview.toWrite) draft.front], ['tip', 'menu']);
  });

  test('with duplicates included they are written too, in row order '
      '(UC-TRANSFER-001 A4)', () {
    final preview = _classify(
      [
        ['front', 'back'],
        ['tip', 'tiền boa'],
        ['bill', 'hóa đơn'],
        ['tip', 'tiền boa'],
      ],
      settings: const ImportSettings(shouldIncludeDuplicates: true),
      deckKeys: {('bill', 'hóa đơn')},
    );

    expect(_statuses(preview), [
      '2 ready',
      '3 duplicate in the deck',
      '4 duplicate of 2',
    ]);
    expect(preview.writeCount, 3);
    expect(
      [for (final draft in preview.toWrite) draft.front],
      ['tip', 'bill', 'tip'],
    );
  });

  test('an invalid row claims no key: a later valid copy of it is ready', () {
    final preview = _classify([
      ['front', 'back', 'hint'],
      ['tip', 'tiền boa', 'h' * 241],
      ['tip', 'tiền boa', ''],
    ]);

    expect(_statuses(preview), [
      '2 invalid hint optionalFieldTooLong',
      '3 ready',
    ]);
  });

  test('blank is every cell of the row, mapped or not; text in an unmapped '
      'column alone leaves the front empty', () {
    final preview = _classify([
      ['front', 'back', 'note'],
      [' ', '\t', ''],
      ['', '', 'a note'],
    ]);

    expect(_statuses(preview), ['2 blank', '3 invalid front blankContent']);
    expect(preview.dataRowCount, 1);
  });

  test('an invalid row keeps its front and back, trimmed, for display', () {
    final row =
        _classify([
              ['front', 'back'],
              ['  bill ', ''],
            ]).rows.single
            as ImportRowInvalid;

    expect((row.front, row.back), ('bill', ''));
  });

  test('the tags cell goes through the codec, and the tag rules judge the '
      'names', () {
    final preview = _classify([
      ['front', 'back', 'tags'],
      ['a', '1', r'noun;x\;y;; '],
      [
        'b',
        '2',
        [for (var i = 0; i < 11; i++) 't$i'].join(';'),
      ],
    ]);

    expect((preview.rows.first as ImportRowReady).draft.tagNames, [
      'noun',
      'x;y',
    ]);
    expect(_statuses(preview).last, '3 invalid tags tooManyTags');
  });

  test('the header row is not a card; without a header the first row is '
      'data, read through columns A and B (UC-TRANSFER-001 A3)', () {
    const rows = [
      ['front', 'back'],
      ['tip', 'tiền boa'],
    ];

    expect(_statuses(_classify(rows)), ['2 ready']);
    final headless = _classify(
      rows,
      settings: const ImportSettings(hasHeaderRow: false),
    );
    expect(_statuses(headless), ['1 ready', '2 ready']);
    expect(headless.mapping.columns, {CardField.front: 0, CardField.back: 1});
  });

  test('a mapping given wins over the default, and a mapped column past '
      'the end of a row reads empty', () {
    final preview = _classify(
      [
        ['a', 'b', 'c'],
        ['x', 'tip', 'tiền boa'],
        ['y', 'bill'],
      ],
      settings: const ImportSettings(
        mapping: ColumnMapping({CardField.front: 1, CardField.back: 2}),
      ),
    );

    expect(_statuses(preview), ['2 ready', '3 invalid back blankContent']);
    expect((preview.rows.first as ImportRowReady).draft.front, 'tip');
  });

  test('without front or back mapped no row is judged, and the data rows '
      'are still counted', () {
    final preview = _classify([
      ['term', 'meaning'],
      ['tip', 'tiền boa'],
      ['', ''],
    ]);

    expect(preview.mapping.missing, {CardField.front, CardField.back});
    expect(preview.rows, isEmpty);
    expect(preview.dataRowCount, 1);
    expect(preview.writeCount, 0);
  });

  test('a source with no data row counts none (UC-TRANSFER-001 E2), and one '
      'with nothing to write has a write count of 0 (E3)', () {
    expect(
      _classify([
        ['front', 'back'],
      ]).dataRowCount,
      0,
    );
    expect(_classify([]).dataRowCount, 0);
    expect(
      _classify([
        ['front', 'back'],
        [' ', ''],
      ]).dataRowCount,
      0,
    );

    final allDuplicates = _classify(
      [
        ['front', 'back'],
        ['tip', 'tiền boa'],
      ],
      deckKeys: {('tip', 'tiền boa')},
    );
    expect(allDuplicates.dataRowCount, 1);
    expect(allDuplicates.writeCount, 0);
  });
}

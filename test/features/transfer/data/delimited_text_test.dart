import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/mappers/delimited_text_mapper.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';

// UC-TRANSFER-001 steps 2-3, A1, E1: a CSV or TSV file, or pasted text,
// read as one sheet (BR-TRANSFER-006; transfer spec §5, D4-D6).

ImportFile _file(String name, List<int> bytes) =>
    ImportFile(name: name, bytes: Uint8List.fromList(bytes));

ImportFile _csv(String text, {String name = 'cards.csv'}) =>
    _file(name, utf8.encode(text));

ImportSheet _sheet(Outcome<ImportDocument, TransferRejection> result) =>
    (result as Ok<ImportDocument, TransferRejection>).value.sheets.single;

List<List<String>> _rows(Outcome<ImportDocument, TransferRejection> result) => [
  for (final row in _sheet(result).rows) row.cells,
];

Matcher _refused(TransferRejection reason) =>
    isA<Rejected<ImportDocument, TransferRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

void main() {
  test('a .csv or .tsv file, in any case, is read; any other extension, or '
      'none, is unsupportedFormat (E1)', () {
    expect(_rows(readDelimited(_csv('a,b', name: 'A.CSV'))), [
      ['a', 'b'],
    ]);
    expect(_rows(readDelimited(_csv('a\tb', name: 'b.Tsv'))), [
      ['a', 'b'],
    ]);
    for (final name in ['c.xlsx', 'd.txt', 'e', 'f.csv.txt', '.csv.bak']) {
      expect(
        readDelimited(_csv('a,b', name: name)),
        _refused(TransferRejection.unsupportedFormat),
        reason: name,
      );
    }
  });

  test('a UTF-8 BOM is dropped; a UTF-16 BOM, bytes that are not UTF-8, or '
      'a U+0000 is notUtf8 (D4, BR-TRANSFER-006)', () {
    expect(
      _rows(
        readDelimited(_file('a.csv', [0xEF, 0xBB, 0xBF, 0x61, 0x2C, 0x62])),
      ),
      [
        ['a', 'b'],
      ],
    );
    for (final (label, bytes) in [
      ('UTF-16 LE', [0xFF, 0xFE, 0x61, 0x00]),
      ('UTF-16 BE', [0xFE, 0xFF, 0x00, 0x61]),
      ('Latin-1 café', [0x63, 0x61, 0x66, 0xE9]),
      ('UTF-16 LE without a BOM', [0x61, 0x00, 0x2C, 0x00, 0x62, 0x00]),
    ]) {
      expect(
        readDelimited(_file('a.csv', bytes)),
        _refused(TransferRejection.notUtf8),
        reason: label,
      );
    }
  });

  test('a .tsv file is split on tabs, whatever else it holds', () {
    expect(_rows(readDelimited(_csv('a,b\tc;d', name: 'x.tsv'))), [
      ['a,b', 'c;d'],
    ]);
  });

  test('a .csv file is split on ";" when its first record holds ";" and no '
      '"," outside quotes, and on "," otherwise (D5)', () {
    expect(_rows(readDelimited(_csv('front;back\ntip;tiền boa'))), [
      ['front', 'back'],
      ['tip', 'tiền boa'],
    ]);
    expect(_rows(readDelimited(_csv('"a,b";c\n"d;e";f'))), [
      ['a,b', 'c'],
      ['d;e', 'f'],
    ]);
    expect(_rows(readDelimited(_csv('\n  \nfront;back'))), [
      [''],
      ['  '],
      ['front', 'back'],
    ]);
    expect(_rows(readDelimited(_csv('front,back\ntip;x,y'))), [
      ['front', 'back'],
      ['tip;x', 'y'],
    ]);
    expect(_rows(readDelimited(_csv('a;b,c'))), [
      ['a;b', 'c'],
    ]);
  });

  test('Excel\'s "CSV UTF-8" from a locale with a decimal comma: a BOM, ";" '
      'between fields, CRLF, a comma in an unquoted cell, and the tags '
      'quoted because they hold ";" (D5)', () {
    final bytes = [
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode('front;back;tags\r\ngiá;1,5 đô;"noun;price"\r\n'),
    ];

    expect(_rows(readDelimited(_file('Từ vựng.csv', bytes))), [
      ['front', 'back', 'tags'],
      ['giá', '1,5 đô', 'noun;price'],
    ]);
  });

  test('pasted text is split on tabs when its first record holds one, and '
      'as a .csv file otherwise (UC-TRANSFER-001 A1)', () {
    expect(
      _rows(readDelimited(const PastedText('term\tmeaning\ntip\ttiền boa'))),
      [
        ['term', 'meaning'],
        ['tip', 'tiền boa'],
      ],
    );
    expect(_rows(readDelimited(const PastedText('a;b'))), [
      ['a', 'b'],
    ]);
    expect(_rows(readDelimited(const PastedText('\uFEFFa,b'))), [
      ['a', 'b'],
    ]);
  });

  test('text copied from a spreadsheet: tabs, CRLF, a cell of two lines in '
      'quotes, and a line break at the end (UC-TRANSFER-001 A1)', () {
    const copied =
        'front\tback\r\n'
        '"line 1\nline 2"\tx\r\n'
        'tip\ttiền boa\r\n';

    expect(_rows(readDelimited(const PastedText(copied))), [
      ['front', 'back'],
      ['line 1\nline 2', 'x'],
      ['tip', 'tiền boa'],
    ]);
  });

  test('a quoted field holds delimiters, line breaks and doubled quotes; '
      'text after its closing quote is kept, and a quote inside an unquoted '
      'field is text (§5.3)', () {
    final result = readDelimited(
      _csv(
        'front,back\n'
        '"a, b","line 1\nline 2"\n'
        '"say ""hi""",x\n'
        '5" screen,"a"b\n',
      ),
    );

    expect(_rows(result), [
      ['front', 'back'],
      ['a, b', 'line 1\nline 2'],
      ['say "hi"', 'x'],
      ['5" screen', 'ab'],
    ]);
    expect([for (final row in _sheet(result).rows) row.number], [1, 2, 3, 4]);
  });

  test('records end at CRLF, LF or CR; a line break at the end adds no '
      'record, and each further one adds a blank row', () {
    expect(_rows(readDelimited(_csv('a,b\r\nc,d\re,f\n'))), [
      ['a', 'b'],
      ['c', 'd'],
      ['e', 'f'],
    ]);
    expect(_rows(readDelimited(_csv('a\n\n'))), [
      ['a'],
      [''],
    ]);
    expect(_rows(readDelimited(_csv(''))), isEmpty);
  });

  test('every field is kept, empty ones included, and the sheet is as wide '
      'as its widest record', () {
    final result = readDelimited(_csv('a,,c\n,\n'));

    expect(_rows(result), [
      ['a', '', 'c'],
      ['', ''],
    ]);
    expect(_sheet(result).columnCount, 3);
  });

  test('a quoted field still open at the end of the source is unreadable '
      '(E1)', () {
    expect(
      readDelimited(_csv('a,"b\nc')),
      _refused(TransferRejection.unreadable),
    );
  });
}

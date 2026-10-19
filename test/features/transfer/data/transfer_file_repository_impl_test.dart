import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

const _files = TransferFileRepositoryImpl();

Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

Future<SourceTable> _table(TransferSource source, {int? sheetIndex}) async {
  final result = await _files.read(source, sheetIndex: sheetIndex);
  return (result as Ok<SourceTable, TransferRejection>).value;
}

Future<TransferRejection> _refusal(TransferSource source) async {
  final result = await _files.read(source);
  return (result as Rejected<SourceTable, TransferRejection>).reason;
}

Future<Uint8List> _written(
  List<List<String>> rows,
  TransferFormat format,
) async {
  final result = await _files.write(rows, format);
  return (result as Ok<Uint8List, TransferRejection>).value;
}

Uint8List _workbook(Map<String, List<List<CellValue?>>> sheets) {
  final workbook = Excel.createExcel();
  final first = workbook.getDefaultSheet()!;
  sheets.forEach((name, rows) {
    final sheet = workbook[name];
    for (final row in rows) {
      sheet.appendRow(row);
    }
  });
  if (!sheets.containsKey(first)) workbook.delete(first);
  return Uint8List.fromList(workbook.encode()!);
}

FileSource _csv(String text) =>
    FileSource(bytes: _utf8(text), format: TransferFormat.csv);

typedef _TableCase = ({
  String name,
  TransferSource source,
  List<List<String>> rows,
});

void main() {
  final tableCases = <_TableCase>[
    (
      name: 'quotes, delimiters and line breaks inside a cell, CRLF and a BOM',
      source: _csv('﻿front,back\r\n"a,b","c\nd"\r\n"say ""hi""",e\r\n'),
      rows: [
        ['front', 'back'],
        ['a,b', 'c\nd'],
        ['say "hi"', 'e'],
      ],
    ),
    (
      name: 'a blank line stays a row, so row numbers match the file',
      source: _csv('front,back\n\na,b\n'),
      rows: [
        ['front', 'back'],
        [''],
        ['a', 'b'],
      ],
    ),
    (
      name: 'TSV splits on tabs only',
      source: FileSource(
        bytes: _utf8('front\tback\na, b\tc'),
        format: TransferFormat.tsv,
      ),
      rows: [
        ['front', 'back'],
        ['a, b', 'c'],
      ],
    ),
    (
      name:
          'a .csv file whose records each hold ";" as often is split on ";", '
          'as Excel saves CSV where the decimal mark is a comma (D9)',
      source: _csv('front;back\r\nmenu;thực đơn\r\n'),
      rows: [
        ['front', 'back'],
        ['menu', 'thực đơn'],
      ],
    ),
    (
      name:
          'a headerless ";" file whose first row holds a comma in a cell '
          'stays ";" (D9)',
      source: _csv('tip;tiền boa, phí phục vụ\nbill;hóa đơn\n'),
      rows: [
        ['tip', 'tiền boa, phí phục vụ'],
        ['bill', 'hóa đơn'],
      ],
    ),
    (
      name: 'a "," file whose first row holds ";" in a cell stays "," (D9)',
      source: _csv('tip,a;b\nbill,c\n'),
      rows: [
        ['tip', 'a;b'],
        ['bill', 'c'],
      ],
    ),
    (
      name: 'a record also ends at a lone CR, as Excel for Mac writes CSV (D9)',
      source: _csv('tip;tiền boa, phí phục vụ\rbill;hóa đơn\r'),
      rows: [
        ['tip', 'tiền boa, phí phục vụ'],
        ['bill', 'hóa đơn'],
      ],
    ),
    (
      name:
          'a file whose rows hold different numbers of delimiters splits on '
          'the one its first row holds: ";" when it holds ";" and no ",", '
          'else "," (D9), ";" first row',
      source: _csv('front;back;tags\nmenu;thực đơn\n'),
      rows: [
        ['front', 'back', 'tags'],
        ['menu', 'thực đơn'],
      ],
    ),
    (
      name:
          'a file whose rows hold different numbers of delimiters splits on '
          'the one its first row holds: ";" when it holds ";" and no ",", '
          'else "," (D9), "," first row',
      source: _csv('front,back,tags\nmenu,thực đơn\n'),
      rows: [
        ['front', 'back', 'tags'],
        ['menu', 'thực đơn'],
      ],
    ),
    (
      name: 'a .csv file never splits on tab (D9)',
      source: _csv('a\tb,c\nd\te,f\n'),
      rows: [
        ['a\tb', 'c'],
        ['d\te', 'f'],
      ],
    ),
    (
      name: 'a delimiter inside quotes does not count (D9)',
      source: _csv('"a,b";c\n"d,e";f\n'),
      rows: [
        ['a,b', 'c'],
        ['d,e', 'f'],
      ],
    ),
    (
      name: 'a delimiter after an escaped quote inside quotes does not count (D9)',
      source: _csv('"nói ""chào"", cười";a\n"hỏi ""ai"", đáp";b\n'),
      rows: [
        ['nói "chào", cười', 'a'],
        ['hỏi "ai", đáp', 'b'],
      ],
    ),
    (
      // The quote after "5" is text: the cell runs on to the quote before ";".
      name:
          'a quote closes its cell, for the vote as for the parser, only '
          'before a delimiter, a line end or the end of the text (D9)',
      source: _csv('"5" screen,x";a\n"7" phone,y";b\n'),
      rows: [
        ['5" screen,x', 'a'],
        ['7" phone,y', 'b'],
      ],
    ),
    (
      name:
          'pasted text is tab-separated when its first record that holds '
          'text has a tab outside quotes (A1)',
      source: const PastedSource('a\tb,c\nd\te'),
      rows: [
        ['a', 'b,c'],
        ['d', 'e'],
      ],
    ),
    (
      name:
          'pasted text with a blank first record is tab-separated by the '
          'first record that holds text (A1)',
      source: const PastedSource('\na\tb,c\nd\te'),
      rows: [
        [''],
        ['a', 'b,c'],
        ['d', 'e'],
      ],
    ),
    (
      // A spreadsheet copies a cell that holds a line break in quotes.
      name:
          'pasted text with a quoted line break before the tab is '
          'tab-separated (A1)',
      source: const PastedSource('"a\nb"\tc\nd\te'),
      rows: [
        ['a\nb', 'c'],
        ['d', 'e'],
      ],
    ),
    (
      name: 'pasted text without a tab reads as a .csv file, "," included (A1)',
      source: const PastedSource('a,b\nc,d'),
      rows: [
        ['a', 'b'],
        ['c', 'd'],
      ],
    ),
    (
      name: 'pasted text without a tab reads as a .csv file, ";" included (A1)',
      source: const PastedSource('a;b\nc;d'),
      rows: [
        ['a', 'b'],
        ['c', 'd'],
      ],
    ),
  ];

  group('CSV and TSV (BR-TRANSFER-006)', () {
    for (final c in tableCases) {
      test(c.name, () async {
        expect((await _table(c.source)).rows, c.rows);
      });
    }

    test(
      'UTF-16, Latin-1 and UTF-16 without a BOM are refused, never guessed',
      () async {
        final utf16 = Uint8List.fromList([0xFF, 0xFE, 0x61, 0x00, 0x2C, 0x00]);
        final latin1 = Uint8List.fromList([0x63, 0x61, 0x66, 0xE9, 0x2C, 0x62]);
        final utf16NoBom = Uint8List.fromList([
          0x61,
          0x00,
          0x2C,
          0x00,
          0x62,
          0x00,
        ]);

        for (final bytes in [utf16, latin1, utf16NoBom]) {
          expect(
            await _refusal(
              FileSource(bytes: bytes, format: TransferFormat.csv),
            ),
            TransferRejection.badEncoding,
          );
        }
      },
    );

    test(
      'the delimiter is judged on the first 20 records that hold text (D9)',
      () async {
        Future<List<List<String>>> rows(String text) async => (await _table(
          FileSource(bytes: _utf8(text), format: TransferFormat.csv),
        )).rows;

        // The 20th record counts: without it both ";" and "," would be steady.
        expect((await rows('${'a;b,c\n' * 19}d;e\n')).last, ['d', 'e']);
        // The 21st does not: with it "," would stop being steady.
        expect((await rows('${'a;b,c\n' * 20}d;e\n')).last, ['d;e']);
        // Blank records are not counted, and still stay rows.
        expect(await rows('\n\na;b\nc;d\n'), [
          [''],
          [''],
          ['a', 'b'],
          ['c', 'd'],
        ]);
      },
    );

    test('a source with nothing in it is empty (E2)', () async {
      expect(
        await _refusal(const PastedSource(' \n , \n')),
        TransferRejection.emptySource,
      );
      expect(
        await _refusal(
          FileSource(bytes: Uint8List(0), format: TransferFormat.csv),
        ),
        TransferRejection.emptySource,
      );
    });
  });

  group('XLSX', () {
    test(
      'the first sheet is read by default, even empty; any sheet can be (A2)',
      () async {
        final bytes = _workbook({
          'Notes': [],
          'Vocab': [
            [TextCellValue('front'), TextCellValue('back')],
            [TextCellValue('menu'), TextCellValue('thực đơn')],
          ],
        });

        final first = await _table(
          FileSource(bytes: bytes, format: TransferFormat.xlsx),
        );
        expect((first.sheetIndex, first.isBlank), (0, true));
        expect(first.sheetNames, ['Notes', 'Vocab']);

        final vocab = await _table(
          FileSource(bytes: bytes, format: TransferFormat.xlsx),
          sheetIndex: 1,
        );
        expect(vocab.sheetIndex, 1);
        expect(vocab.rows.last, ['menu', 'thực đơn']);
      },
    );

    test(
      'a workbook with one blank sheet is still an empty source (E2)',
      () async {
        final bytes = _workbook({'Only': []});

        expect(
          await _refusal(FileSource(bytes: bytes, format: TransferFormat.xlsx)),
          TransferRejection.emptySource,
        );
      },
    );

    test('numbers and dates read as text', () async {
      final bytes = _workbook({
        'Sheet1': [
          [
            const IntCellValue(7),
            const DoubleCellValue(2.0),
            const DoubleCellValue(2.5),
            const DateCellValue(year: 2026, month: 9, day: 1),
            null,
          ],
        ],
      });

      final table = await _table(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
      );
      expect(table.rows.single, ['7', '2', '2.5', '2026-09-01', '']);
    });

    test('bytes that are not a workbook are unreadable (E1)', () async {
      expect(
        await _refusal(
          FileSource(bytes: _utf8('front,back'), format: TransferFormat.xlsx),
        ),
        TransferRejection.unreadableFile,
      );
    });
  });

  group('writing (BR-TRANSFER-010, BR-TRANSFER-012)', () {
    const rows = [
      ['front', 'back', 'example', 'hint', 'pronunciation', 'tags'],
      ['=1+1', '001', '', '', '', r'a\;b;c'],
      ['say "hi"', 'x,y\nz', '', '', '', ''],
    ];

    test('CSV and TSV start with a BOM, and read back as written', () async {
      for (final format in [TransferFormat.csv, TransferFormat.tsv]) {
        final bytes = await _written(rows, format);

        expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
        expect(
          (await _table(FileSource(bytes: bytes, format: format))).rows,
          rows,
        );
      }
    });

    test('the same rows give the same CSV bytes', () async {
      expect(
        await _written(rows, TransferFormat.csv),
        await _written(rows, TransferFormat.csv),
      );
    });

    test('XLSX writes text cells: no formula, no number, and reads back as written', () async {
      final bytes = await _written(rows, TransferFormat.xlsx);
      final sheet = Excel.decodeBytes(bytes).tables.values.single;

      expect(sheet.rows[1][0]!.value, isA<TextCellValue>());
      expect(sheet.rows[1][1]!.value, isA<TextCellValue>());
      expect(
        (await _table(FileSource(bytes: bytes, format: TransferFormat.xlsx)))
            .rows,
        rows,
      );
    });
  });
}

import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

import 'transfer_file_harness.dart';

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

void main() {
  group('CSV and TSV (BR-TRANSFER-006)', () {
    test(
      'quotes, delimiters and line breaks inside a cell, CRLF and a BOM',
      () async {
        final table = await tableOf(
          FileSource(
            bytes: utf8Bytes(
              '﻿front,back\r\n"a,b","c\nd"\r\n"say ""hi""",e\r\n',
            ),
            format: TransferFormat.csv,
          ),
        );

        expect(table.rows, [
          ['front', 'back'],
          ['a,b', 'c\nd'],
          ['say "hi"', 'e'],
        ]);
      },
    );

    test('a blank line stays a row, so row numbers match the file', () async {
      final table = await tableOf(
        FileSource(
          bytes: utf8Bytes('front,back\n\na,b\n'),
          format: TransferFormat.csv,
        ),
      );

      expect(table.rows, [
        ['front', 'back'],
        [''],
        ['a', 'b'],
      ]);
    });

    test('TSV splits on tabs only', () async {
      final table = await tableOf(
        FileSource(
          bytes: utf8Bytes('front\tback\na, b\tc'),
          format: TransferFormat.tsv,
        ),
      );

      expect(table.rows.last, ['a, b', 'c']);
    });

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
            await refusalOf(
              FileSource(bytes: bytes, format: TransferFormat.csv),
            ),
            TransferRejection.badEncoding,
          );
        }
      },
    );

    test('a .csv file whose records each hold ";" as often is split on ";", as '
        'Excel saves CSV where the decimal mark is a comma (D9)', () async {
      final table = await tableOf(
        FileSource(
          bytes: utf8Bytes('front;back\r\nmenu;thực đơn\r\n'),
          format: TransferFormat.csv,
        ),
      );

      expect(table.rows, [
        ['front', 'back'],
        ['menu', 'thực đơn'],
      ]);
    });

    test(
      'a headerless ";" file whose first row holds a comma in a cell stays '
      '";", and a "," file whose first row holds ";" in a cell stays "," (D9)',
      () async {
        final semicolons = await tableOf(
          FileSource(
            bytes: utf8Bytes('tip;tiền boa, phí phục vụ\nbill;hóa đơn\n'),
            format: TransferFormat.csv,
          ),
        );
        final commas = await tableOf(
          FileSource(
            bytes: utf8Bytes('tip,a;b\nbill,c\n'),
            format: TransferFormat.csv,
          ),
        );

        expect(semicolons.rows, [
          ['tip', 'tiền boa, phí phục vụ'],
          ['bill', 'hóa đơn'],
        ]);
        expect(commas.rows, [
          ['tip', 'a;b'],
          ['bill', 'c'],
        ]);
      },
    );

    test('a record also ends at a lone CR, as Excel for Mac writes CSV '
        '(D9)', () async {
      final table = await tableOf(
        FileSource(
          bytes: utf8Bytes('tip;tiền boa, phí phục vụ\rbill;hóa đơn\r'),
          format: TransferFormat.csv,
        ),
      );

      expect(table.rows, [
        ['tip', 'tiền boa, phí phục vụ'],
        ['bill', 'hóa đơn'],
      ]);
    });

    test('a file whose rows hold different numbers of delimiters splits on the '
        'one its first row holds: ";" when it holds ";" and no ",", else "," '
        '(D9)', () async {
      final semicolons = await tableOf(
        FileSource(
          bytes: utf8Bytes('front;back;tags\nmenu;thực đơn\n'),
          format: TransferFormat.csv,
        ),
      );
      final commas = await tableOf(
        FileSource(
          bytes: utf8Bytes('front,back,tags\nmenu,thực đơn\n'),
          format: TransferFormat.csv,
        ),
      );

      expect(semicolons.rows, [
        ['front', 'back', 'tags'],
        ['menu', 'thực đơn'],
      ]);
      expect(commas.rows, [
        ['front', 'back', 'tags'],
        ['menu', 'thực đơn'],
      ]);
    });

    test('a .csv file never splits on tab (D9)', () async {
      final table = await tableOf(
        FileSource(
          bytes: utf8Bytes('a\tb,c\nd\te,f\n'),
          format: TransferFormat.csv,
        ),
      );

      expect(table.rows, [
        ['a\tb', 'c'],
        ['d\te', 'f'],
      ]);
    });

    test('a delimiter inside quotes does not count, nor after an escaped '
        'quote inside them (D9)', () async {
      final quoted = await tableOf(
        FileSource(
          bytes: utf8Bytes('"a,b";c\n"d,e";f\n'),
          format: TransferFormat.csv,
        ),
      );
      final escaped = await tableOf(
        FileSource(
          bytes: utf8Bytes('"nói ""chào"", cười";a\n"hỏi ""ai"", đáp";b\n'),
          format: TransferFormat.csv,
        ),
      );

      expect(quoted.rows, [
        ['a,b', 'c'],
        ['d,e', 'f'],
      ]);
      expect(escaped.rows, [
        ['nói "chào", cười', 'a'],
        ['hỏi "ai", đáp', 'b'],
      ]);
    });

    test('a quote closes its cell, for the vote as for the parser, only '
        'before a delimiter, a line end or the end of the text (D9)', () async {
      // The quote after "5" is text: the cell runs on to the quote before ";".
      final table = await tableOf(
        FileSource(
          bytes: utf8Bytes('"5" screen,x";a\n"7" phone,y";b\n'),
          format: TransferFormat.csv,
        ),
      );

      expect(table.rows, [
        ['5" screen,x', 'a'],
        ['7" phone,y', 'b'],
      ]);
    });

    test(
      'the delimiter is judged on the first 20 records that hold text (D9)',
      () async {
        Future<List<List<String>>> rows(String text) async => (await tableOf(
          FileSource(bytes: utf8Bytes(text), format: TransferFormat.csv),
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

    test('pasted text is tab-separated when its first record that holds text '
        'has a tab outside quotes (A1)', () async {
      expect((await tableOf(const PastedSource('a\tb,c\nd\te'))).rows, [
        ['a', 'b,c'],
        ['d', 'e'],
      ]);
      expect((await tableOf(const PastedSource('\na\tb,c\nd\te'))).rows, [
        [''],
        ['a', 'b,c'],
        ['d', 'e'],
      ]);
      // A spreadsheet copies a cell that holds a line break in quotes.
      expect((await tableOf(const PastedSource('"a\nb"\tc\nd\te'))).rows, [
        ['a\nb', 'c'],
        ['d', 'e'],
      ]);
      expect((await tableOf(const PastedSource('a,b\nc,d'))).rows.last, [
        'c',
        'd',
      ]);
    });

    test(
      'pasted text without a tab reads as a .csv file, ";" included (A1)',
      () async {
        expect((await tableOf(const PastedSource('a;b\nc;d'))).rows, [
          ['a', 'b'],
          ['c', 'd'],
        ]);
      },
    );

    test('a source with nothing in it is empty (E2)', () async {
      expect(
        await refusalOf(const PastedSource(' \n , \n')),
        TransferRejection.emptySource,
      );
      expect(
        await refusalOf(
          FileSource(bytes: Uint8List(0), format: TransferFormat.csv),
        ),
        TransferRejection.emptySource,
      );
    });
  });

  group('XLSX', () {
    test('the first sheet that holds anything is chosen, and any sheet can be (A2)', () async {
      final bytes = _workbook({
        'Notes': [],
        'Vocab': [
          [TextCellValue('front'), TextCellValue('back')],
          [TextCellValue('menu'), TextCellValue('thực đơn')],
        ],
        'Other': [
          [TextCellValue('x')],
        ],
      });

      final table = await tableOf(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
      );
      expect(table.sheetNames, ['Notes', 'Vocab', 'Other']);
      expect(table.sheetIndex, 1);
      expect(table.rows.last, ['menu', 'thực đơn']);

      final other = await tableOf(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
        sheetIndex: 2,
      );
      expect(other.rows, [
        ['x'],
      ]);
    });

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

      final table = await tableOf(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
      );
      expect(table.rows.single, ['7', '2', '2.5', '2026-09-01', '']);
    });

    test('bytes that are not a workbook are unreadable (E1)', () async {
      expect(
        await refusalOf(
          FileSource(
            bytes: utf8Bytes('front,back'),
            format: TransferFormat.xlsx,
          ),
        ),
        TransferRejection.unreadableFile,
      );
    });
  });
}

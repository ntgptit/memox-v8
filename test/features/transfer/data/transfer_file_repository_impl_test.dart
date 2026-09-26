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

void main() {
  group('CSV and TSV (BR-TRANSFER-006)', () {
    test(
      'quotes, delimiters and line breaks inside a cell, CRLF and a BOM',
      () async {
        final table = await _table(
          FileSource(
            bytes: _utf8('﻿front,back\r\n"a,b","c\nd"\r\n"say ""hi""",e\r\n'),
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
      final table = await _table(
        FileSource(
          bytes: _utf8('front,back\n\na,b\n'),
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
      final table = await _table(
        FileSource(
          bytes: _utf8('front\tback\na, b\tc'),
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
            await _refusal(
              FileSource(bytes: bytes, format: TransferFormat.csv),
            ),
            TransferRejection.badEncoding,
          );
        }
      },
    );

    test(
      'pasted text is tab-separated when its first line has a tab (A1)',
      () async {
        expect((await _table(const PastedSource('a\tb,c\nd\te'))).rows, [
          ['a', 'b,c'],
          ['d', 'e'],
        ]);
        expect((await _table(const PastedSource('a,b\nc,d'))).rows.last, [
          'c',
          'd',
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

      final table = await _table(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
      );
      expect(table.sheetNames, ['Notes', 'Vocab', 'Other']);
      expect(table.sheetIndex, 1);
      expect(table.rows.last, ['menu', 'thực đơn']);

      final other = await _table(
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

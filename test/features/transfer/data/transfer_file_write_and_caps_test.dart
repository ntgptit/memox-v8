import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_limits_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

import 'transfer_file_harness.dart';

// The file repository's output and its caps: writing a table out
// (BR-TRANSFER-010, BR-TRANSFER-012) and the size caps (SP2a 2.23).

Future<Uint8List> _written(
  List<List<String>> rows,
  TransferFormat format,
) async {
  final result = await transferFiles.write(rows, format);
  return (result as Ok<Uint8List, TransferRejection>).value;
}

void main() {
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
          (await tableOf(FileSource(bytes: bytes, format: format))).rows,
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
        (await tableOf(FileSource(bytes: bytes, format: TransferFormat.xlsx)))
            .rows,
        rows,
      );
    });
  });

  group('size caps (SP2a 2.23)', () {
    test('a file over 5 MB is refused before it is decoded', () async {
      // Not UTF-8: decoding would answer badEncoding, so the cap came first.
      final bytes = Uint8List(TransferLimits.maxBytes + 1)
        ..fillRange(0, 4, 0xFF);

      expect(
        await refusalOf(FileSource(bytes: bytes, format: TransferFormat.csv)),
        TransferRejection.tooLarge,
      );
      expect(
        await refusalOf(FileSource(bytes: bytes, format: TransferFormat.xlsx)),
        TransferRejection.tooLarge,
      );
    });

    test('exactly 5 MB is read; one byte more is refused', () async {
      // One row whose size is the cap, so only the byte gate is in play.
      Uint8List sized(int length) =>
          Uint8List.fromList(utf8.encode('a,${'x' * (length - 2)}'));

      final table = await tableOf(
        FileSource(
          bytes: sized(TransferLimits.maxBytes),
          format: TransferFormat.csv,
        ),
      );
      expect(table.rows, hasLength(1));
      expect(
        await refusalOf(
          FileSource(
            bytes: sized(TransferLimits.maxBytes + 1),
            format: TransferFormat.csv,
          ),
        ),
        TransferRejection.tooLarge,
      );
    });

    test('a paste is counted in UTF-8 bytes, as a file is: exactly 5 MB is '
        'read; one byte more is refused', () async {
      // Two bytes per "é": the paste is under the cap in UTF-16 units and
      // over it in bytes.
      final atCap = 'a,${'é' * ((TransferLimits.maxBytes - 2) ~/ 2)}';
      expect(utf8.encode(atCap), hasLength(TransferLimits.maxBytes));

      expect((await tableOf(PastedSource(atCap))).rows, hasLength(1));
      expect(
        await refusalOf(PastedSource('${atCap}x')),
        TransferRejection.tooLarge,
      );
      // Over in bytes while its length in UTF-16 units is at most the cap.
      final multibyte = 'a,${'ế' * (TransferLimits.maxBytes ~/ 3 + 1)}';
      expect(multibyte.length, lessThan(TransferLimits.maxBytes));
      expect(
        await refusalOf(PastedSource(multibyte)),
        TransferRejection.tooLarge,
      );
    });

    test('a table over 20,000 rows is refused; 20,000 rows are read', () async {
      String rows(int count) => List.filled(count, 'a,b').join('\n');

      expect(
        await refusalOf(PastedSource(rows(TransferLimits.maxRows + 1))),
        TransferRejection.tooLarge,
      );
      expect(
        (await tableOf(PastedSource(rows(TransferLimits.maxRows)))).rows,
        hasLength(TransferLimits.maxRows),
      );
    });
  });
}

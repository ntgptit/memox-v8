import 'dart:typed_data';

import 'package:excel/excel.dart';

/// XLSX through the `excel` package: the only file that imports it (spec
/// D4). Should the package break, this file is the whole replacement.
final class XlsxDataSource {
  const XlsxDataSource();

  static const exportSheetName = 'cards';

  /// The workbook's sheet names in order, and the rows of the sheet at
  /// [sheetIndex], or of the first sheet that holds anything when it is null
  /// (UC-TRANSFER-001 A2). Every cell reads as text. Throws when the bytes
  /// are not a readable workbook.
  ({List<String> sheetNames, int sheetIndex, List<List<String>> rows}) read(
    Uint8List bytes, {
    int? sheetIndex,
  }) {
    final sheets = Excel.decodeBytes(bytes).tables;
    final sheetNames = sheets.keys.toList();
    final tables = [
      for (final name in sheetNames)
        [
          for (final row in sheets[name]!.rows)
            [for (final cell in row) _textOf(cell?.value)],
        ],
    ];
    final chosen = sheetIndex ?? _firstFilled(tables) ?? 0;
    return (
      sheetNames: sheetNames,
      sheetIndex: chosen,
      rows: chosen < tables.length ? tables[chosen] : const [],
    );
  }

  /// One sheet whose every cell is a text cell, so `=`, `+`, `-` and `@`
  /// never start a formula and `001` stays `001` (BR-TRANSFER-012).
  Uint8List write(List<List<String>> rows) {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet()!;
    workbook.rename(defaultSheet, exportSheetName);
    final sheet = workbook[exportSheetName];
    for (final row in rows) {
      sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
    }
    final bytes = workbook.encode();
    if (bytes == null) throw StateError('workbook not encoded');
    return Uint8List.fromList(bytes);
  }

  int? _firstFilled(List<List<List<String>>> tables) {
    for (var index = 0; index < tables.length; index++) {
      final filled = tables[index].any(
        (row) => row.any((cell) => cell.trim().isNotEmpty),
      );
      if (filled) return index;
    }
    return null;
  }
}

/// A date as `yyyy-mm-dd`; a whole number without a decimal point; any other
/// value as the package prints it.
String _textOf(CellValue? value) => switch (value) {
  null => '',
  DateCellValue(:final year, :final month, :final day) =>
    '${_digits(year, 4)}-${_digits(month, 2)}-${_digits(day, 2)}',
  DoubleCellValue(:final value) when value == value.truncateToDouble() =>
    value.toInt().toString(),
  _ => value.toString(),
};

String _digits(int value, int width) => value.toString().padLeft(width, '0');

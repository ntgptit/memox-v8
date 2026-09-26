import 'dart:math' show max;

/// One record of an import source: its number in the source, from 1, and
/// its cells as read, untrimmed (transfer spec §5).
final class ImportRow {
  const ImportRow({required this.number, required this.cells});

  final int number;
  final List<String> cells;

  /// Every cell is empty after trim (BR-TRANSFER-002).
  bool get isBlank => cells.every((cell) => cell.trim().isEmpty);

  /// The cell of [column], or the empty string past the end of the row.
  String cellAt(int column) => column < cells.length ? cells[column] : '';
}

/// A table read from a source: a CSV or TSV file and pasted text are one
/// sheet; a workbook has one per sheet (package 9b).
final class ImportSheet {
  const ImportSheet({this.name, required this.rows});

  /// Null but in a workbook.
  final String? name;
  final List<ImportRow> rows;

  /// The number of cells of the widest row.
  int get columnCount =>
      rows.fold(0, (widest, row) => max(widest, row.cells.length));

  /// No row holds anything but whitespace.
  bool get isEmpty => rows.every((row) => row.isBlank);
}

/// What a source reads as: its sheets, in order.
final class ImportDocument {
  const ImportDocument(this.sheets);

  final List<ImportSheet> sheets;

  /// The first sheet that is not empty, or the first sheet
  /// (UC-TRANSFER-001 A2).
  int get defaultSheetIndex {
    final index = sheets.indexWhere((sheet) => !sheet.isEmpty);
    return index < 0 ? 0 : index;
  }
}

/// The name a spreadsheet gives the column at [index]: 0 is A, 25 is Z and
/// 26 is AA (UC-TRANSFER-001 A3).
String columnLetter(int index) {
  var letters = '';
  for (var rest = index + 1; rest > 0; rest = (rest - 1) ~/ 26) {
    letters = String.fromCharCode(0x41 + (rest - 1) % 26) + letters;
  }
  return letters;
}

/// A source read into rows of text cells, before any mapping
/// (UC-TRANSFER-001 steps 3–4). Rows keep their order and their blank rows,
/// so a row's number is its index plus one.
final class SourceTable {
  const SourceTable({
    required this.rows,
    this.sheetNames = const [],
    this.sheetIndex = 0,
  });

  /// Every row as read, a header row included; every cell as text.
  final List<List<String>> rows;

  /// The sheets of an XLSX workbook, in workbook order; empty for CSV, TSV
  /// and pasted text (UC-TRANSFER-001 A2).
  final List<String> sheetNames;

  /// Which of [sheetNames] [rows] came from.
  final int sheetIndex;

  /// The width of the widest row.
  int get columnCount =>
      rows.fold(0, (widest, row) => row.length > widest ? row.length : widest);

  /// Whether no cell holds anything but white space (UC-TRANSFER-001 E2).
  bool get isBlank => rows.every((row) => row.every(_isBlankCell));
}

bool _isBlankCell(String cell) => cell.trim().isEmpty;

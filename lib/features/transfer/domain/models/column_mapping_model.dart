import 'package:memox/core/text/folded_text.dart';

/// The six content fields a transfer file carries, in file order, each named
/// by its canonical header (BR-TRANSFER-008, BR-TRANSFER-012).
enum TransferField {
  front,
  back,
  example,
  hint,
  pronunciation,
  tags;

  /// The canonical header: the name itself, lower case English, never
  /// localized.
  String get header => name;
}

/// Which source column feeds which field (UC-TRANSFER-001 step 4). A column
/// feeds at most one field and a field takes at most one column
/// (BR-TRANSFER-002).
final class ColumnMapping {
  const ColumnMapping(this.fieldByColumn);

  /// A header cell equal to a canonical header after [foldText] maps to that
  /// field; the first column wins a field. Nothing else is guessed.
  factory ColumnMapping.fromHeader(List<String> header) {
    final fieldByColumn = <int, TransferField>{};
    for (var column = 0; column < header.length; column++) {
      final folded = foldText(header[column]);
      for (final field in TransferField.values) {
        if (field.header != folded) continue;
        if (fieldByColumn.containsValue(field)) continue;
        fieldByColumn[column] = field;
      }
    }
    return ColumnMapping(fieldByColumn);
  }

  final Map<int, TransferField> fieldByColumn;

  /// Maps [column] to [field], or leaves it unmapped when [field] is null. A
  /// field moved here leaves the column that had it.
  ColumnMapping assign(int column, TransferField? field) {
    final next = {
      for (final entry in fieldByColumn.entries)
        if (entry.key != column && entry.value != field) entry.key: entry.value,
    };
    if (field != null) next[column] = field;
    return ColumnMapping(next);
  }

  int? columnOf(TransferField field) {
    for (final entry in fieldByColumn.entries) {
      if (entry.value == field) return entry.key;
    }
    return null;
  }

  /// Whether both faces are mapped (BR-TRANSFER-002).
  bool get isComplete =>
      columnOf(TransferField.front) != null &&
      columnOf(TransferField.back) != null;
}

/// The position name of a column when the first row is not a header
/// (UC-TRANSFER-001 A3): A…Z, then AA, AB….
String columnLetter(int column) {
  const letters = 26;
  final codeOfA = 'A'.codeUnitAt(0);
  final name = <String>[];
  for (var rest = column + 1; rest > 0; rest = (rest - 1) ~/ letters) {
    name.insert(0, String.fromCharCode(codeOfA + (rest - 1) % letters));
  }
  return name.join();
}

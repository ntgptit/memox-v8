import 'package:memox/features/card/domain/models/card_field_model.dart';

/// The header of each field in a transfer file, in file order: English,
/// lowercase, never localized (BR-TRANSFER-008, BR-TRANSFER-012).
const canonicalHeaders = {
  CardField.front: 'front',
  CardField.back: 'back',
  CardField.example: 'example',
  CardField.hint: 'hint',
  CardField.pronunciation: 'pronunciation',
  CardField.tags: 'tags',
};

/// Which column of a sheet feeds which field of a card: each field at most
/// one column, each column at most one field (UC-TRANSFER-001 step 4,
/// BR-TRANSFER-002; transfer spec D7).
final class ColumnMapping {
  const ColumnMapping([this.columns = const {}]);

  /// Each field reads the first column whose header cell, trimmed and in
  /// any case, is its canonical header.
  factory ColumnMapping.byHeader(List<String> headerCells) {
    final columns = <CardField, int>{};
    for (final (column, cell) in headerCells.indexed) {
      final name = cell.trim().toLowerCase();
      for (final MapEntry(key: field, value: header)
          in canonicalHeaders.entries) {
        if (header == name) columns.putIfAbsent(field, () => column);
      }
    }
    return ColumnMapping(columns);
  }

  /// With no header, column A is the front and column B the back, when the
  /// sheet has them (UC-TRANSFER-001 A3).
  factory ColumnMapping.byPosition(int columnCount) => ColumnMapping({
    if (columnCount > 0) CardField.front: 0,
    if (columnCount > 1) CardField.back: 1,
  });

  final Map<CardField, int> columns;

  int? columnOf(CardField field) => columns[field];

  CardField? fieldAt(int column) {
    for (final MapEntry(key: field, value: at) in columns.entries) {
      if (at == column) return field;
    }
    return null;
  }

  /// [field] reads [column]; the field the column fed before, if any, and
  /// the column the field read before, if any, are let go.
  ColumnMapping assign(CardField field, int column) => ColumnMapping({
    for (final MapEntry(key: other, value: at) in columns.entries)
      if (other != field && at != column) other: at,
    field: column,
  });

  ColumnMapping unassign(CardField field) => ColumnMapping({
    for (final MapEntry(key: other, value: at) in columns.entries)
      if (other != field) other: at,
  });

  /// The fields every row needs that no column feeds (BR-TRANSFER-002).
  Set<CardField> get missing => {
    for (final field in const [CardField.front, CardField.back])
      if (!columns.containsKey(field)) field,
  };
}

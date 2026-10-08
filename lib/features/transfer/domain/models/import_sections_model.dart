import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

/// A data row whose `front` cell starts with this names a deck
/// (BR-TRANSFER-015).
const importSectionMarker = '*';

/// The rows of one deck in a sectioned source (BR-TRANSFER-015).
final class ImportSection {
  const ImportSection({
    required this.name,
    required this.isDefault,
    required this.rowIndexes,
  });

  /// The text after the marker, trimmed; empty for the default section,
  /// which the preview names (spec 2026-10-08 S4).
  final String name;

  /// The rows before the first section row.
  final bool isDefault;

  /// Indexes into the table of the card rows, in source order.
  final List<int> rowIndexes;
}

/// The sections of [table] in order of first appearance, or null when no
/// data row is a section row (a flat source). Names that fold equal are one
/// section. The default section comes first, and only when a row before
/// the first section row holds text.
List<ImportSection>? splitSections({
  required SourceTable table,
  required ColumnMapping mapping,
  required bool hasHeaderRow,
}) {
  final frontColumn = mapping.columnOf(TransferField.front);
  if (frontColumn == null) return null;
  final defaultRows = <int>[];
  final names = <String>[];
  final rowsByKey = <String, List<int>>{};
  String? currentKey;
  for (var index = hasHeaderRow ? 1 : 0; index < table.rows.length; index++) {
    final cells = table.rows[index];
    final front = frontColumn < cells.length ? cells[frontColumn].trim() : '';
    if (front.startsWith(importSectionMarker)) {
      final name = front.substring(importSectionMarker.length).trim();
      final key = foldText(name);
      if (!rowsByKey.containsKey(key)) {
        names.add(name);
        rowsByKey[key] = [];
      }
      currentKey = key;
      continue;
    }
    if (currentKey == null) {
      defaultRows.add(index);
      continue;
    }
    rowsByKey[currentKey]!.add(index);
  }
  if (names.isEmpty) return null;
  final hasDefault = defaultRows.any(
    (index) => !isBlankRow(table.rows[index], mapping),
  );
  return [
    if (hasDefault)
      ImportSection(name: '', isDefault: true, rowIndexes: defaultRows),
    for (final name in names)
      ImportSection(
        name: name,
        isDefault: false,
        rowIndexes: rowsByKey[foldText(name)]!,
      ),
  ];
}

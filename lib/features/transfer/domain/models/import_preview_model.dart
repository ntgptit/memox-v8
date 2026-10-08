import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/tags_cell_model.dart';

/// What the preview decided for one data row (UC-TRANSFER-001 step 5).
enum ImportRowKind { ready, invalid, duplicateInDeck, duplicateInSource, blank }

final class ImportRow {
  const ImportRow({
    required this.rowNumber,
    required this.kind,
    this.draft,
    this.reason,
    this.firstRowNumber,
    this.deckNameReason,
  });

  /// The row's number in the source, the header row counted.
  final int rowNumber;
  final ImportRowKind kind;

  /// Null only for a blank row.
  final CardDraft? draft;

  /// Why an invalid row is refused: the first failing card rule.
  final CardRejection? reason;

  /// For a duplicate within the source: the row it repeats.
  final int? firstRowNumber;

  /// Why the deck this row's section names is refused (BR-TRANSFER-015,
  /// BR-DECK-020); such a row is invalid whatever its cells hold.
  final DeckRejection? deckNameReason;

  bool get isDuplicate =>
      kind == ImportRowKind.duplicateInDeck ||
      kind == ImportRowKind.duplicateInSource;
}

/// Every data row with its status, and the counts the preview shows. It
/// writes nothing (BR-TRANSFER-006).
final class ImportPreview {
  const ImportPreview(this.rows);

  final List<ImportRow> rows;

  int get total => rows.length;
  int get ready => _count(ImportRowKind.ready);
  int get invalid => _count(ImportRowKind.invalid);
  int get blank => _count(ImportRowKind.blank);
  int get duplicates => rows.where((row) => row.isDuplicate).length;

  /// Whether no data row holds anything (UC-TRANSFER-001 E2).
  bool get isEmpty => blank == total;

  /// "Include duplicates" writes both duplicate kinds as new cards (A4).
  int willWrite({required bool includeDuplicates}) =>
      ready + (includeDuplicates ? duplicates : 0);

  /// The rows a commit writes, in source order (A4).
  List<ImportRow> rowsToWrite({required bool includeDuplicates}) => [
    for (final row in rows)
      if (row.kind == ImportRowKind.ready ||
          (includeDuplicates && row.isDuplicate))
        row,
  ];

  int _count(ImportRowKind kind) =>
      rows.where((row) => row.kind == kind).length;
}

/// Decides each data row's status in order: blank, invalid, duplicate of a
/// card in the deck ([existing]), duplicate of an earlier valid row, ready
/// (BR-TRANSFER-002, BR-TRANSFER-003). The mapping must be complete.
ImportPreview buildImportPreview({
  required SourceTable table,
  required ColumnMapping mapping,
  required bool hasHeaderRow,
  required Set<CardFoldedPair> existing,
}) => ImportPreview(
  classifyRows(
    table: table,
    rowIndexes: [
      for (var index = hasHeaderRow ? 1 : 0; index < table.rows.length; index++)
        index,
    ],
    mapping: mapping,
    existing: existing,
  ),
);

/// Each row of [rowIndexes] (indexes into [table]), in order: blank,
/// invalid, duplicate of [existing], duplicate of an earlier row given here,
/// ready (BR-TRANSFER-002, BR-TRANSFER-003). The mapping must be complete.
List<ImportRow> classifyRows({
  required SourceTable table,
  required Iterable<int> rowIndexes,
  required ColumnMapping mapping,
  required Set<CardFoldedPair> existing,
}) {
  final firstRowOf = <CardFoldedPair, int>{};
  final rows = <ImportRow>[];
  for (final index in rowIndexes) {
    final rowNumber = index + 1;
    final cells = table.rows[index];
    String? cell(TransferField field) => _cellOf(cells, mapping, field);

    if (isBlankRow(cells, mapping)) {
      rows.add(ImportRow(rowNumber: rowNumber, kind: ImportRowKind.blank));
      continue;
    }
    final draft = CardDraft(
      front: cell(TransferField.front) ?? '',
      back: cell(TransferField.back) ?? '',
      example: cell(TransferField.example),
      hint: cell(TransferField.hint),
      pronunciation: cell(TransferField.pronunciation),
      tagNames: TagsCell.decode(cell(TransferField.tags) ?? ''),
    );
    if (draft.check() case Rejected(:final reason)) {
      rows.add(
        ImportRow(
          rowNumber: rowNumber,
          kind: ImportRowKind.invalid,
          draft: draft,
          reason: reason,
        ),
      );
      continue;
    }
    final pair = (front: foldText(draft.front), back: foldText(draft.back));
    if (existing.contains(pair)) {
      rows.add(
        ImportRow(
          rowNumber: rowNumber,
          kind: ImportRowKind.duplicateInDeck,
          draft: draft,
        ),
      );
      continue;
    }
    final firstRowNumber = firstRowOf[pair];
    if (firstRowNumber != null) {
      rows.add(
        ImportRow(
          rowNumber: rowNumber,
          kind: ImportRowKind.duplicateInSource,
          draft: draft,
          firstRowNumber: firstRowNumber,
        ),
      );
      continue;
    }
    firstRowOf[pair] = rowNumber;
    rows.add(
      ImportRow(rowNumber: rowNumber, kind: ImportRowKind.ready, draft: draft),
    );
  }
  return rows;
}

/// Whether every mapped cell of [cells] is empty after trim
/// (BR-TRANSFER-002).
bool isBlankRow(List<String> cells, ColumnMapping mapping) =>
    [for (final field in TransferField.values) _cellOf(cells, mapping, field)]
        .every((value) => value == null || value.trim().isEmpty);

String? _cellOf(
  List<String> cells,
  ColumnMapping mapping,
  TransferField field,
) {
  final column = mapping.columnOf(field);
  if (column == null || column >= cells.length) return null;
  return cells[column];
}

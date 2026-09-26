import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/tag_cell_model.dart';

/// What the person chose before the preview (UC-TRANSFER-001 steps 4-5).
final class ImportSettings {
  const ImportSettings({
    this.hasHeaderRow = true,
    this.mapping,
    this.shouldIncludeDuplicates = false,
  });

  final bool hasHeaderRow;

  /// Null for the default of the header choice (transfer spec D7).
  final ColumnMapping? mapping;

  /// UC-TRANSFER-001 A4.
  final bool shouldIncludeDuplicates;
}

/// A row's duplicate key: its front and back folded as `card` stores them,
/// `front_folded` and `back_folded` (BR-TRANSFER-003).
typedef ContentKey = (String frontFolded, String backFolded);

/// The status of one data row of the preview.
sealed class ImportRowOutcome {
  const ImportRowOutcome(this.rowNumber);

  /// The row's number in the source.
  final int rowNumber;
}

final class ImportRowReady extends ImportRowOutcome {
  const ImportRowReady(super.rowNumber, this.draft);

  final CardDraft draft;
}

/// A valid row whose key the target deck holds ([firstRowNumber] null), or
/// an earlier row of the source claimed.
final class ImportRowDuplicate extends ImportRowOutcome {
  const ImportRowDuplicate(super.rowNumber, this.draft, {this.firstRowNumber});

  final CardDraft draft;
  final int? firstRowNumber;
}

/// A row the card's own rules refuse (BR-TRANSFER-002): the first failing
/// [field] and its [reason], with the row's front and back, trimmed.
final class ImportRowInvalid extends ImportRowOutcome {
  const ImportRowInvalid(
    super.rowNumber, {
    required this.front,
    required this.back,
    required this.field,
    required this.reason,
  });

  final String front;
  final String back;
  final CardField field;
  final CardRejection reason;
}

/// A row with nothing in any cell: skipped, and not an error
/// (BR-TRANSFER-002).
final class ImportRowBlank extends ImportRowOutcome {
  const ImportRowBlank(super.rowNumber);
}

/// The preview of an import (UC-TRANSFER-001 step 5): the data rows of a
/// sheet, each with its status. The commit classifies the rows again, with
/// the same rules, on the deck as it is then (BR-TRANSFER-003).
final class ImportPreview {
  const ImportPreview._({
    required this.mapping,
    required this.shouldIncludeDuplicates,
    required this.rows,
    required this.dataRowCount,
  });

  /// Classifies the data rows of [sheet] against [deckKeys], the keys of the
  /// target deck's active cards, in order (transfer spec §6.2): blank, then
  /// invalid, then a duplicate in the deck, then a duplicate of an earlier
  /// row, else ready. A valid row claims its key when no earlier row has;
  /// an invalid row claims nothing. No row is classified while front or
  /// back has no column.
  factory ImportPreview.classify({
    required ImportSheet sheet,
    required ImportSettings settings,
    required Set<ContentKey> deckKeys,
  }) {
    final dataRows = settings.hasHeaderRow
        ? sheet.rows.skip(1).toList()
        : sheet.rows;
    final mapping = settings.mapping ?? _defaultMapping(sheet, settings);
    final claimed = <ContentKey, int>{};
    return ImportPreview._(
      mapping: mapping,
      shouldIncludeDuplicates: settings.shouldIncludeDuplicates,
      rows: mapping.missing.isNotEmpty
          ? const []
          : [
              for (final row in dataRows)
                _classify(row, mapping, deckKeys, claimed),
            ],
      dataRowCount: dataRows.where((row) => !row.isBlank).length,
    );
  }

  /// The mapping the rows were read through, the default or the one given.
  final ColumnMapping mapping;

  final bool shouldIncludeDuplicates;

  /// Every data row, in source order; none while the mapping is missing
  /// front or back.
  final List<ImportRowOutcome> rows;

  /// The data rows that are not blank, whatever the mapping: none is
  /// UC-TRANSFER-001 E2.
  final int dataRowCount;

  int get readyCount => rows.whereType<ImportRowReady>().length;

  int get duplicateCount => rows.whereType<ImportRowDuplicate>().length;

  int get invalidCount => rows.whereType<ImportRowInvalid>().length;

  int get blankCount => rows.whereType<ImportRowBlank>().length;

  /// How many cards the import would write: none is UC-TRANSFER-001 E3.
  int get writeCount => toWrite.length;

  /// The drafts the import writes, in row order: the ready rows, and the
  /// duplicates when the person includes them (BR-TRANSFER-003).
  List<CardDraft> get toWrite => [
    for (final row in rows)
      if (row case ImportRowReady(:final draft))
        draft
      else if (row case ImportRowDuplicate(:final draft)
          when shouldIncludeDuplicates)
        draft,
  ];
}

ColumnMapping _defaultMapping(ImportSheet sheet, ImportSettings settings) {
  if (!settings.hasHeaderRow) {
    return ColumnMapping.byPosition(sheet.columnCount);
  }
  if (sheet.rows.isEmpty) return const ColumnMapping();
  return ColumnMapping.byHeader(sheet.rows.first.cells);
}

ImportRowOutcome _classify(
  ImportRow row,
  ColumnMapping mapping,
  Set<ContentKey> deckKeys,
  Map<ContentKey, int> claimed,
) {
  if (row.isBlank) return ImportRowBlank(row.number);
  String? cellOf(CardField field) => switch (mapping.columnOf(field)) {
    final int column => row.cellAt(column),
    null => null,
  };
  final front = cellOf(CardField.front) ?? '';
  final back = cellOf(CardField.back) ?? '';
  final draft = CardDraft(
    front: front,
    back: back,
    example: cellOf(CardField.example),
    hint: cellOf(CardField.hint),
    pronunciation: cellOf(CardField.pronunciation),
    tagNames: switch (cellOf(CardField.tags)) {
      final String cell => TagCell.decode(cell),
      null => const [],
    },
  );
  if (draft.firstFailure() case (:final field, :final reason)) {
    return ImportRowInvalid(
      row.number,
      front: front.trim(),
      back: back.trim(),
      field: field,
      reason: reason,
    );
  }
  final ContentKey key = (foldText(front), foldText(back));
  final first = claimed.putIfAbsent(key, () => row.number);
  if (deckKeys.contains(key)) return ImportRowDuplicate(row.number, draft);
  if (first != row.number) {
    return ImportRowDuplicate(row.number, draft, firstRowNumber: first);
  }
  return ImportRowReady(row.number, draft);
}

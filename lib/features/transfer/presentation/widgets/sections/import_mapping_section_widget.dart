import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Step 2 of the import (kit 11): whether the first row is a header, and the
/// field each column feeds. An unmapped face says so on its own row, above
/// the note (BR-TRANSFER-002; kit deviation K3).
class ImportMappingSectionWidget extends StatelessWidget {
  const ImportMappingSectionWidget({
    super.key,
    required this.draft,
    required this.onHeaderRow,
    required this.onAssign,
  });

  final CardImportDraft draft;
  final ValueChanged<bool> onHeaderRow;
  final void Function(int column, TransferField? field) onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final table = draft.table!;
    // Row 1's cells, header or not: the toggle's subtitle shows what it
    // governs (SP2a 2.24).
    final firstRow = table.rows.isEmpty ? null : table.rows.first;
    final header = draft.hasHeaderRow ? firstRow : null;
    String? headerOf(int column) =>
        header != null && column < header.length ? header[column] : null;
    // The first data row, so a column is recognised by what it holds
    // (critique 2026-09-30 part 1): row 2 under a header, else row 1.
    final firstData = draft.hasHeaderRow ? 1 : 0;
    final sampleRow = table.rows.length > firstData
        ? table.rows[firstData]
        : null;
    String? sampleOf(int column) {
      if (sampleRow == null || column >= sampleRow.length) return null;
      final cell = sampleRow[column].trim();
      return cell.isEmpty ? null : cell;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxSection(
          title: l10n.importSectionColumns,
          children: [
            MxSettingsRow(
              label: l10n.importHeaderToggle,
              onTap: () => onHeaderRow(!draft.hasHeaderRow),
              subtitle: firstRow
                  ?.where((cell) => cell.trim().isNotEmpty)
                  .join(' · '),
              trailing: MxToggle(
                isOn: draft.hasHeaderRow,
                onChanged: onHeaderRow,
                semanticLabel: l10n.importHeaderToggle,
              ),
            ),
            for (var column = 0; column < table.columnCount; column++)
              ImportMappingRowWidget(
                column: column,
                header: headerOf(column),
                sample: sampleOf(column),
                field: draft.mapping.fieldByColumn[column],
                onAssign: (field) => onAssign(column, field),
              ),
          ],
        ),
        // The deck could not be read for the preview: nothing was lost, so a
        // warning, and Preview rows is live again (SP2a 2.22, audit M2).
        if (draft.problem == TransferRejection.previewFailed) ...[
          MxInlineBanner(
            tone: MxBannerTone.warning,
            title: l10n.importProblem(TransferRejection.previewFailed).title,
            message: l10n.importProblem(TransferRejection.previewFailed).body,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
        if (!draft.mapping.isComplete) ...[
          MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.importMappingIncomplete,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
        // It says known header names were mapped: only once they are, and
        // only while row 1 is read as a header (SP2a audit m5).
        if (draft.mapping.isComplete && draft.hasHeaderRow)
          MxNote.hint(text: l10n.importMappingNote),
      ],
    );
  }
}

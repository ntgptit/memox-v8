import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart';
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
    final header = draft.hasHeaderRow && table.rows.isNotEmpty
        ? table.rows.first
        : null;
    String? headerOf(int column) =>
        header != null && column < header.length ? header[column] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxSection(
          title: l10n.importSectionColumns,
          children: [
            MxSettingsRow(
              label: l10n.importHeaderToggle,
              onTap: () => onHeaderRow(!draft.hasHeaderRow),
              subtitle: header
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
                field: draft.mapping.fieldByColumn[column],
                onAssign: (field) => onAssign(column, field),
              ),
          ],
        ),
        if (!draft.mapping.isComplete) ...[
          MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.importMappingIncomplete,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
        // It says columns were mapped: only once they are.
        if (draft.mapping.isComplete) MxNote(text: l10n.importMappingNote),
      ],
    );
  }
}

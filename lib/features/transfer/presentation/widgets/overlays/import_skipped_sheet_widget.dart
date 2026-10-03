import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Opens every row the import skipped (SP2a 2.23). The result lists five
/// inline; the rest are here, built only as they scroll into view, so a
/// 20,000-row file with thousands of skips stays light.
Future<void> showImportSkippedSheet(
  BuildContext context, {
  required List<ImportRow> rows,
}) => showMxBottomSheet<void>(
  context,
  builder: (_) => ImportSkippedSheetWidget(rows: rows),
);

class ImportSkippedSheetWidget extends StatelessWidget {
  const ImportSkippedSheetWidget({super.key, required this.rows});

  final List<ImportRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet.builder(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          l10n.importSkippedHeader,
          style: context.textStyles.compactTitle,
        ),
      ),
      itemCount: rows.length,
      itemBuilder: (_, index) => ImportPreviewRowWidget(row: rows[index]),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.importCloseAction,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/import_option_sheet_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// One source column and the field it feeds (kit 11 mapping row): its
/// position name, the header it had, its first value, and a picker of the
/// six fields or none.
class ImportMappingRowWidget extends StatelessWidget {
  const ImportMappingRowWidget({
    super.key,
    required this.column,
    required this.header,
    this.sample,
    required this.field,
    required this.onAssign,
  });

  final int column;

  /// The first row's cell, when the first row is a header.
  final String? header;

  /// The first data row's cell, trimmed; null when empty or missing
  /// (critique 2026-09-30 part 1).
  final String? sample;
  final TransferField? field;
  final ValueChanged<TransferField?> onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final letter = columnLetter(column);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.grouped,
      ),
      child: Row(
        spacing: AppSpacing.control,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                Text(
                  l10n.importColumnName(letter),
                  style: styles.rowDescription,
                ),
                if (header case final text? when text.trim().isNotEmpty)
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: styles.contentTitle,
                  ),
                if (sample case final text?)
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.rowDescription,
                  ),
              ],
            ),
          ),
          // No arrow between the column and its field: it sat at a
          // different x on every row (critique 2026-09-30); the chips end on
          // one edge.
          MxChipTrigger(
            label: l10n.importField(field),
            onPressed: () => showImportOptionSheet<TransferField?>(
              context,
              title: l10n.importFieldPickerTitle(letter),
              options: const [null, ...TransferField.values],
              selected: field,
              label: l10n.importField,
              onSelected: onAssign,
            ),
          ),
        ],
      ),
    );
  }
}

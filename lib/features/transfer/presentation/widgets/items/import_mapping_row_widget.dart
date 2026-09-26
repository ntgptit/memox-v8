import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/import_option_sheet_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// One source column and the field it feeds (kit 11 mapping row): its
/// position name, the header it had, and a picker of the six fields or none.
class ImportMappingRowWidget extends StatelessWidget {
  const ImportMappingRowWidget({
    super.key,
    required this.column,
    required this.header,
    required this.field,
    required this.onAssign,
  });

  final int column;

  /// The first row's cell, when the first row is a header.
  final String? header;
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
              ],
            ),
          ),
          ExcludeSemantics(
            child: IconTheme.merge(
              data: IconThemeData(
                color: context.colors.onSurfaceVariant,
                size: AppIconSize.inline,
              ),
              child: const Icon(AppIcons.arrowRight),
            ),
          ),
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

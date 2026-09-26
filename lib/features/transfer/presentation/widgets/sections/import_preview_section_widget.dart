import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Step 3 of the import (kit 11): the counts, the first rows with their
/// status, and the duplicate policy (UC-TRANSFER-001 step 5, A4). A large
/// source shows its first rows and says so (kit deviation K2).
class ImportPreviewSectionWidget extends StatelessWidget {
  const ImportPreviewSectionWidget({
    super.key,
    required this.draft,
    required this.onIncludeDuplicates,
  });

  final CardImportDraft draft;
  final ValueChanged<bool> onIncludeDuplicates;

  /// The rows the table shows before "Showing the first …" (K2).
  static const int shownRows = 50;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = draft.preview!;
    final shown = preview.rows.take(shownRows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(
          label: l10n.importSectionPreview,
          trailing: Text(
            l10n.importPreviewReady(preview.ready, preview.total),
            style: context.textStyles.counter,
          ),
        ),
        Wrap(
          spacing: AppSpacing.micro,
          runSpacing: AppSpacing.micro,
          children: [
            if (preview.ready > 0)
              MxBadge(
                label: l10n.importBadgeReady(preview.ready),
                tone: MxBadgeTone.mastery,
                icon: AppIcons.check,
              ),
            if (preview.invalid > 0)
              MxBadge(
                label: l10n.importBadgeInvalid(preview.invalid),
                tone: MxBadgeTone.warning,
                icon: AppIcons.alert,
              ),
            if (preview.duplicates > 0)
              MxBadge(
                label: l10n.importBadgeDuplicate(preview.duplicates),
                tone: MxBadgeTone.neutral,
                icon: AppIcons.cardDeck,
              ),
            if (preview.blank > 0)
              MxBadge(
                label: l10n.importBadgeBlank(preview.blank),
                tone: MxBadgeTone.neutral,
                icon: AppIcons.remove,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxSection(
          note: preview.total > shown.length
              ? l10n.importShowingFirst(shown.length, preview.total)
              : null,
          children: [for (final row in shown) ImportPreviewRowWidget(row: row)],
        ),
        if (preview.duplicates > 0)
          MxSection(
            children: [
              MxSettingsRow(
                label: l10n.importIncludeDuplicates,
                subtitle: l10n.importIncludeDuplicatesBody,
                onTap: () => onIncludeDuplicates(!draft.isIncludingDuplicates),
                trailing: MxToggle(
                  isOn: draft.isIncludingDuplicates,
                  onChanged: onIncludeDuplicates,
                  semanticLabel: l10n.importIncludeDuplicates,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

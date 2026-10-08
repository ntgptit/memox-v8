import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_decks_section_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Step 3 of the import (kit 11): the counts, the first rows with their
/// status, and the duplicate policy (UC-TRANSFER-001 step 5, A4). A large
/// source shows its first rows and says so (kit deviation K2). A sectioned
/// source shows its decks first and its rows grouped by deck (spec
/// 2026-10-08 U2, U5).
class ImportPreviewSectionWidget extends StatelessWidget {
  const ImportPreviewSectionWidget({
    super.key,
    required this.draft,
    required this.onIncludeDuplicates,
    required this.onChooseSection,
    required this.onRenameDefault,
    required this.onPreviewAgain,
  });

  final CardImportDraft draft;
  final ValueChanged<bool> onIncludeDuplicates;
  final void Function(int index, ImportSectionChoice choice) onChooseSection;
  final ValueChanged<String> onRenameDefault;

  /// Reads the decks again after one changed before Import (E9).
  final VoidCallback onPreviewAgain;

  /// The rows the table shows before "Showing the first …" (K2).
  static const int shownRows = 50;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = draft.preview!;
    final problem = draft.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem != null && isStalePreviewProblem(problem)) ...[
          MxInlineBanner(
            tone: MxBannerTone.warning,
            title: l10n.importProblem(problem).title,
            message: l10n.importProblem(problem).body,
            actions: [
              MxButton(
                label: l10n.importPreviewAgain,
                tone: MxButtonTone.text,
                size: MxButtonSize.compact,
                onPressed: onPreviewAgain,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
        // The chips below carry the breakdown: no total beside the title
        // (critique 2026-09-30 part 3b).
        MxListSectionHeader(label: l10n.importSectionPreview),
        Wrap(
          spacing: AppSpacing.micro,
          runSpacing: AppSpacing.micro,
          children: [
            if (preview.ready > 0)
              MxBadge(
                label: l10n.importBadgeReady(preview.ready),
                tone: MxBadgeTone.success,
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
        // Before the rows it governs (critique 2026-09-30 part 3d-2, E10).
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
        if (preview.isSectioned) ...[
          ImportDecksSectionWidget(
            preview: preview,
            isIncludingDuplicates: draft.isIncludingDuplicates,
            onChoose: onChooseSection,
            onRename: onRenameDefault,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
        ..._rowSections(context, preview),
      ],
    );
  }

  /// One section of rows per group, the first [shownRows] across the whole
  /// import (K2, U5); the note goes under the last section shown.
  List<Widget> _rowSections(BuildContext context, ImportPreview preview) {
    final l10n = context.l10n;
    final shown = <(ImportGroup, List<ImportRow>)>[];
    var left = shownRows;
    for (final group in preview.groups) {
      if (left == 0) break;
      final rows = group.rows.take(left).toList();
      if (rows.isEmpty) continue;
      left -= rows.length;
      shown.add((group, rows));
    }
    final shownCount = shownRows - left;
    return [
      for (final (index, (group, rows)) in shown.indexed)
        MxSection(
          title: preview.isSectioned ? group.name : null,
          note: index == shown.length - 1 && preview.total > shownCount
              ? l10n.importShowingFirst(shownCount, preview.total)
              : null,
          children: [for (final row in rows) ImportPreviewRowWidget(row: row)],
        ),
    ];
  }
}

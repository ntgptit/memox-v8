import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/presentation/widgets/support/tag_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// A tag's three commands (kit 05 `sheet`).
enum TagAction { findCards, rename, delete }

/// Opens [tag]'s commands; completes with the chosen one, or null.
Future<TagAction?> showTagActionsSheet(
  BuildContext context, {
  required TagCount tag,
}) => showMxBottomSheet<TagAction>(
  context,
  builder: (_) => TagActionsSheetWidget(tag: tag),
);

/// Find cards, Rename (which may merge, A1) and Delete, the one destructive
/// command (A3).
class TagActionsSheetWidget extends StatelessWidget {
  const TagActionsSheetWidget({super.key, required this.tag});

  final TagCount tag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void choose(TagAction action) => Navigator.of(context).pop(action);
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            MxTagChip(label: tagWithCount(tag.name, tag.cardCount)),
            Text(
              l10n.tagsActionsCaption,
              style: context.textStyles.rowDescription,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.search,
              label: l10n.tagsFindCards,
              subtitle: l10n.tagsFindCardsHint(tag.name),
              hasChevron: true,
              onTap: () => choose(TagAction.findCards),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.edit,
              label: l10n.tagsRename,
              subtitle: l10n.tagsRenameHint,
              hasChevron: true,
              onTap: () => choose(TagAction.rename),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: l10n.tagsDelete,
              subtitle: l10n.tagsDeleteHint(tag.cardCount),
              isDestructive: true,
              onTap: () => choose(TagAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

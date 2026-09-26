import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

/// A Trash entry's two commands (kit 06 actions).
enum TrashEntryAction { restore, purge }

/// Opens [entry]'s commands; completes with the chosen one, or null when
/// dismissed.
Future<TrashEntryAction?> showTrashEntryActionsSheet(
  BuildContext context, {
  required TrashEntry entry,
  required DateTime now,
}) => showMxBottomSheet<TrashEntryAction>(
  context,
  builder: (_) => TrashEntryActionsSheetWidget(entry: entry, now: now),
);

/// Restore asks for a target (BR-TRASH-006); Delete permanently is the one
/// destructive command (BR-TRASH-011).
class TrashEntryActionsSheetWidget extends StatelessWidget {
  const TrashEntryActionsSheetWidget({
    super.key,
    required this.entry,
    required this.now,
  });

  final TrashEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final ago = trashDeletedAgo(l10n, entry.deletedAt, now);
    final parent = trashParent(l10n, entry);
    void choose(TrashEntryAction action) => Navigator.of(context).pop(action);
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
            Text(
              trashEntryName(entry),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: styles.compactTitle,
            ),
            Text(switch (entry) {
              TrashCardEntry() => l10n.trashCardActionsMeta(ago, parent),
              TrashDeckEntry() => l10n.trashDeckActionsMeta(ago, parent),
            }, style: styles.rowDescription),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.restore,
              label: l10n.trashRestore,
              subtitle: l10n.trashRestoreHint,
              hasChevron: true,
              onTap: () => choose(TrashEntryAction.restore),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: l10n.trashDeletePermanently,
              subtitle: l10n.trashDeletePermanentlyHint,
              isDestructive: true,
              hasChevron: true,
              onTap: () => choose(TrashEntryAction.purge),
            ),
          ],
        ),
      ),
    );
  }
}

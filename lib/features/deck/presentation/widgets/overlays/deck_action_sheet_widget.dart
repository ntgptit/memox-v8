import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

/// What the deck action sheet can start (spec §6.2).
enum DeckAction { rename, move, changeScheduler, reorder, delete }

/// The open deck's commands. It completes with the chosen one, which the
/// screen then opens, or with null when dismissed.
Future<DeckAction?> showDeckActionSheet(
  BuildContext context, {
  required DeckView view,
  required bool canReorder,
}) => showMxBottomSheet<DeckAction>(
  context,
  builder: (_) => DeckActionSheetWidget(view: view, canReorder: canReorder),
);

class DeckActionSheetWidget extends StatelessWidget {
  const DeckActionSheetWidget({
    super.key,
    required this.view,
    required this.canReorder,
  });

  final DeckView view;
  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deck = view.deck;
    void choose(DeckAction action) => Navigator.of(context).pop(action);
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          deck.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.compactTitle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.edit,
              label: l10n.deckRename,
              onTap: () => choose(DeckAction.rename),
            ),
            // Ruling P2-L8: a root cannot move, and only a root has a
            // scheduler.
            if (!deck.isRoot)
              MxActionSheetCommandRow(
                icon: AppIcons.folder,
                label: l10n.deckMove,
                hasChevron: true,
                onTap: () => choose(DeckAction.move),
              ),
            if (deck.isRoot)
              MxActionSheetCommandRow(
                icon: AppIcons.scheduler,
                label: l10n.deckChangeScheduler,
                subtitle: l10n.schedulerType(view.schedulerType),
                hasChevron: true,
                onTap: () => choose(DeckAction.changeScheduler),
              ),
            if (canReorder)
              MxActionSheetCommandRow(
                icon: AppIcons.reorder,
                label: l10n.deckReorder,
                onTap: () => choose(DeckAction.reorder),
              ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: l10n.deckDelete,
              isDestructive: true,
              onTap: () => choose(DeckAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

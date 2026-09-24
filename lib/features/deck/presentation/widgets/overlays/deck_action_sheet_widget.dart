import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/shared/widgets/mx_unavailable.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

/// What the deck action sheet can start (spec §6.2).
enum DeckAction { open, rename, move, reviewAlgorithm, reorder, delete }

/// A deck's commands (screen 01), from its row's ⋮ or the open deck's ⋮. It
/// completes with the chosen one, which the caller then opens, or with null
/// when dismissed.
Future<DeckAction?> showDeckActionSheet(
  BuildContext context, {
  required DeckView view,
  required bool canReorder,
  required bool hasOpen,
}) => showMxBottomSheet<DeckAction>(
  context,
  builder: (_) => DeckActionSheetWidget(
    view: view,
    canReorder: canReorder,
    hasOpen: hasOpen,
  ),
);

class DeckActionSheetWidget extends StatelessWidget {
  const DeckActionSheetWidget({
    super.key,
    required this.view,
    required this.canReorder,
    required this.hasOpen,
  });

  final DeckView view;
  final bool canReorder;

  /// From a row, the deck is not open yet; Open leads.
  final bool hasOpen;

  @override
  Widget build(BuildContext context) {
    final deck = view.deck;
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
        child: Column(children: _rows(context)),
      ),
    );
  }

  /// Study and Study options exist in the handoff but not in V8.0 yet: they
  /// show disabled (spec A4). Root decks own the algorithm and cannot move
  /// (ruling P2-L8).
  List<Widget> _rows(BuildContext context) {
    final l10n = context.l10n;
    final deck = view.deck;
    void choose(DeckAction action) => Navigator.of(context).pop(action);
    final algorithm = l10n.schedulerType(view.schedulerType);
    return [
      if (hasOpen)
        MxActionSheetCommandRow(
          icon: AppIcons.folder,
          label: l10n.deckOpen,
          onTap: () => choose(DeckAction.open),
        ),
      MxUnavailable(
        hint: context.l10n.commonNotAvailableYet,
        child: MxActionSheetCommandRow(
          icon: AppIcons.play,
          label: l10n.deckStudyThis,
          onTap: () {},
          isEnabled: false,
        ),
      ),
      MxActionSheetCommandRow(
        icon: AppIcons.edit,
        label: l10n.deckRename,
        onTap: () => choose(DeckAction.rename),
      ),
      if (deck.isRoot) ...[
        MxUnavailable(
          hint: context.l10n.commonNotAvailableYet,
          child: MxActionSheetCommandRow(
            icon: AppIcons.settings,
            label: l10n.deckStudyOptions,
            subtitle: l10n.deckStudyOptionsHint,
            onTap: () {},
            isEnabled: false,
          ),
        ),
        MxActionSheetCommandRow(
          icon: AppIcons.scheduler,
          label: l10n.deckReviewAlgorithm,
          subtitle: view.isSchedulerLocked
              ? l10n.deckReviewAlgorithmLocked(algorithm)
              : algorithm,
          hasChevron: true,
          onTap: () => choose(DeckAction.reviewAlgorithm),
        ),
      ],
      if (!deck.isRoot)
        MxActionSheetCommandRow(
          icon: AppIcons.folder,
          label: l10n.deckMove,
          hasChevron: true,
          onTap: () => choose(DeckAction.move),
        ),
      if (canReorder)
        MxActionSheetCommandRow(
          icon: AppIcons.reorder,
          label: l10n.deckReorder,
          subtitle: l10n.deckReorderHint,
          onTap: () => choose(DeckAction.reorder),
        ),
      MxActionSheetCommandRow(
        icon: AppIcons.delete,
        label: l10n.deckDelete,
        isDestructive: true,
        onTap: () => choose(DeckAction.delete),
      ),
    ];
  }
}

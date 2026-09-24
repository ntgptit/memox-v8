import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_reorder_mode_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_scheduler_sheet_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Opens a deck's action sheet and then the chosen command's own dialog or
/// sheet (spec §6.2): from a row's ⋮, or from the open deck's ⋮. It reads
/// the deck's view once first, so a deck gone meanwhile says so instead
/// (ruling C-L6).
Future<void> openDeckActions(
  BuildContext context,
  WidgetRef ref, {
  required String deckId,
  required String? parentId,
  required ValueChanged<String> onOpenDeck,
  required bool isOpenDeck,
}) async {
  // A row's deck has no listener yet: keep its view alive until it emits,
  // or the auto-disposed provider would never complete the read.
  final provider = deckViewProvider(deckId);
  final keepAlive = ref.listenManual(provider, (_, _) {});
  final Outcome<DeckView, DeckRejection> outcome;
  try {
    outcome = await ref.read(provider.future);
  } finally {
    keepAlive.close();
  }
  if (!context.mounted) return;
  final view = switch (outcome) {
    Ok(:final value) => value,
    Rejected() => null,
  };
  if (view == null) {
    showMxSnackbar(context, message: context.l10n.deckDeletedToast);
    return;
  }
  // The open deck reorders its children; a row reorders its siblings.
  final reorderLevel = isOpenDeck ? deckId : parentId;
  final canReorder = ref.read(deckLevelCanReorderProvider(reorderLevel));
  final action = await showDeckActionSheet(
    context,
    view: view,
    canReorder: canReorder,
    hasOpen: !isOpenDeck,
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case DeckAction.open:
      onOpenDeck(deckId);
    case DeckAction.rename:
      await showRenameDeckDialog(context, deck: view.deck);
    case DeckAction.move:
      await showMoveDeckSheet(context, deck: view.deck);
    case DeckAction.changeScheduler:
      await showDeckSchedulerSheet(context, view: view);
    case DeckAction.reorder:
      ref.read(deckReorderModeProvider(reorderLevel).notifier).start();
    case DeckAction.delete:
      await showDeleteDeckDialog(context, deck: view.deck);
  }
}

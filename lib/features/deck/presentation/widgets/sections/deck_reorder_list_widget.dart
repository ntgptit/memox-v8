import 'dart:async';

import 'package:flutter/material.dart' show ReorderableListView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_reorder_anchor_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/support/held_run.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// A level's decks in drag-to-reorder mode (spec §6.1, ruling P2-L3). Each
/// drop is one `ReorderDeckUseCase` call. The dropped order shows at once,
/// and the stream's next order, or the stored one after a refusal, wins.
class DeckReorderListWidget extends ConsumerStatefulWidget {
  const DeckReorderListWidget({super.key, required this.tiles});

  final List<DeckTile> tiles;

  @override
  ConsumerState<DeckReorderListWidget> createState() =>
      _DeckReorderListWidgetState();
}

class _DeckReorderListWidgetState extends ConsumerState<DeckReorderListWidget> {
  late List<DeckTile> _order = widget.tiles;

  /// Drops still saving. Until they land, the level may still carry the old
  /// order, so an update keeps the dropped order and takes only fresh data.
  var _savingDrops = 0;

  @override
  void didUpdateWidget(DeckReorderListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _order = _savingDrops == 0 ? widget.tiles : _inDroppedOrder(widget.tiles);
  }

  List<DeckTile> _inDroppedOrder(List<DeckTile> fresh) {
    final byId = {for (final tile in fresh) tile.id: tile};
    final shown = {for (final tile in _order) tile.id};
    return [
      for (final tile in _order) ?byId[tile.id],
      for (final tile in fresh)
        if (!shown.contains(tile.id)) tile,
    ];
  }

  Future<void> _drop(int oldIndex, int newIndex) async {
    final anchor = deckReorderAnchor(
      [for (final tile in _order) tile.id],
      oldIndex,
      newIndex,
    );
    if (anchor == null) return;
    final moving = _order[oldIndex];
    setState(() {
      _order = [..._order]
        ..removeAt(oldIndex)
        ..insert(newIndex, moving);
    });
    _savingDrops++;
    await runHeld(
      () async {
        final outcome = await ref
            .read(deckActionsControllerProvider.notifier)
            .reorderDeck(
              deckId: moving.id,
              anchorId: anchor.anchorId,
              placement: anchor.placement,
            );
        _savingDrops--;
        if (!mounted) return;
        if (outcome case Rejected(:final reason)) {
          setState(() => _order = widget.tiles);
          showMxSnackbar(context, message: context.l10n.deckRejection(reason));
        }
      },
      onFailed: (failure) {
        _savingDrops--;
        if (!mounted) return;
        setState(() => _order = widget.tiles);
        showMxSnackbar(context, message: context.l10n.heldFailure(failure));
      },
    );
  }

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
    buildDefaultDragHandles: false,
    padding: EdgeInsets.fromLTRB(
      context.screenMargin,
      context.dimens.space16,
      context.screenMargin,
      context.dimens.space24 + MediaQuery.paddingOf(context).bottom,
    ),
    itemCount: _order.length,
    onReorderItem: (oldIndex, newIndex) => unawaited(_drop(oldIndex, newIndex)),
    itemBuilder: (context, index) => Padding(
      key: ValueKey(_order[index].id),
      padding: EdgeInsets.only(
        bottom: index < _order.length - 1 ? context.dimens.space8 : 0,
      ),
      child: DeckReorderRowWidget(tile: _order[index], index: index),
    ),
  );
}

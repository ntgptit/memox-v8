import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/states/card_search_open_state.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// A deck of cards' app bar (screen 07): Back, the deck's name, the search
/// action and the deck's actions; while cards are selected it becomes the
/// selection header, Close, the count and Select all (A14, ruling E-L3).
class CardDeckAppBarWidget extends ConsumerWidget {
  const CardDeckAppBarWidget({
    super.key,
    required this.view,
    required this.deckActions,
  });

  final DeckView view;

  /// The deck's ⋮, from the deck screen.
  final Widget deckActions;

  String get _deckId => view.deck.id;

  /// Every card the filter and the term let through, beyond the loaded
  /// window (RF1).
  Future<void> _selectAll(BuildContext context, WidgetRef ref) async {
    final query = ref.read(cardListRequestProvider(_deckId)).query;
    try {
      final ids = await ref
          .read(cardActionsControllerProvider.notifier)
          .selectAll(deckId: _deckId, query: query);
      if (!context.mounted) return;
      ref.read(cardSelectionProvider(_deckId).notifier).selectAll(ids);
    } on Failure catch (failure) {
      if (!context.mounted) return;
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  void _toggleSearch(WidgetRef ref, {required bool isOpen}) {
    final search = ref.read(cardSearchOpenProvider(_deckId).notifier);
    if (isOpen) return search.close();
    search.open();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(cardSelectionProvider(_deckId));
    if (selected.isNotEmpty) {
      final request = ref.watch(cardListRequestProvider(_deckId));
      final list = ref.watch(
        cardListProvider(
          deckId: _deckId,
          filter: request.filter,
          sort: request.sort,
          searchTerm: request.searchTerm,
          windowSize: request.windowSize,
        ),
      );
      final total = list.value?.counts.of(request.filter);
      return MxAppBar(
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.close,
          semanticLabel: l10n.cardSelectionClose,
          onPressed: () =>
              ref.read(cardSelectionProvider(_deckId).notifier).clear(),
        ),
        // TalkBack reads the new count as it changes.
        titleWidget: Semantics(
          liveRegion: true,
          child: Text(
            l10n.cardSelectedCount(selected.length),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.compactTitle,
          ),
        ),
        actions: [
          if (total != null)
            MxButton(
              label: l10n.cardSelectAllCount(total),
              tone: MxButtonTone.secondary,
              size: MxButtonSize.compact,
              onPressed: () => unawaited(_selectAll(context, ref)),
            ),
        ],
      );
    }
    final isSearchOpen = ref.watch(cardSearchOpenProvider(_deckId));
    return MxAppBar(
      title: view.deck.name,
      density: MxAppBarDensity.content,
      leading: MxIconButton(
        icon: AppIcons.back,
        semanticLabel: l10n.commonBack,
        onPressed: () => unawaited(Navigator.of(context).maybePop()),
      ),
      actions: [
        MxIconButton(
          icon: isSearchOpen ? AppIcons.close : AppIcons.search,
          semanticLabel: isSearchOpen
              ? l10n.cardSearchClose
              : l10n.cardSearchOpen,
          onPressed: () => _toggleSearch(ref, isOpen: isSearchOpen),
        ),
        deckActions,
      ],
    );
  }
}

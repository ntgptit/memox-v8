import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// The app bar of a deck of cards (screen 07, owner decision E-O1): the
/// deck's back, name and `⋮` with the card search action, or, while cards
/// are selected, close, "N selected" and "Select all M". The deck screen
/// hands in [leading] and [actions]; `deck` never imports `card` (D8).
class CardDeckAppBarWidget extends ConsumerWidget {
  const CardDeckAppBarWidget({
    super.key,
    required this.deckId,
    required this.title,
    required this.leading,
    required this.actions,
  });

  final String deckId;
  final String title;
  final Widget leading;
  final List<Widget> actions;

  CardListRequest _request(WidgetRef ref) =>
      ref.read(cardListRequestProvider(deckId).notifier);

  CardSelection _selection(WidgetRef ref) =>
      ref.read(cardSelectionProvider(deckId).notifier);

  /// Every card the query lets through, not only the loaded rows
  /// (BR-CARD-012).
  Future<void> _selectAll(
    BuildContext context,
    WidgetRef ref,
    CardListQuery query,
  ) async {
    try {
      final ids = await ref
          .read(cardActionsControllerProvider.notifier)
          .selectAll(deckId: deckId, query: query);
      if (!context.mounted) return;
      _selection(ref).selectAll(ids);
    } on Failure catch (failure) {
      if (!context.mounted) return;
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final request = ref.watch(cardListRequestProvider(deckId));
    final selected = ref.watch(cardSelectionProvider(deckId));
    if (selected.isEmpty) {
      final isOpen = request.isSearchOpen;
      return MxAppBar(
        title: title,
        density: MxAppBarDensity.content,
        leading: leading,
        actions: [
          MxIconButton(
            icon: isOpen ? AppIcons.close : AppIcons.search,
            semanticLabel: isOpen ? l10n.cardCloseSearch : l10n.cardOpenSearch,
            onPressed: isOpen
                ? () => _request(ref).closeSearch()
                : () => _request(ref).openSearch(),
          ),
          ...actions,
        ],
      );
    }
    // The same list the section shows, so the count matches its rows.
    final view = ref
        .watch(
          cardListProvider(
            deckId: deckId,
            filter: request.filter,
            sort: request.sort,
            searchTerm: request.searchTerm,
            windowSize: request.windowSize,
          ),
        )
        .value;
    final total = view?.counts.of(request.filter);
    return MxAppBar(
      titleWidget: Semantics(
        liveRegion: true,
        child: Text(
          l10n.cardSelectedCount(selected.length),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.contentTitle,
        ),
      ),
      density: MxAppBarDensity.content,
      leading: MxIconButton(
        icon: AppIcons.close,
        semanticLabel: l10n.cardSelectionClose,
        onPressed: () => _selection(ref).clear(),
      ),
      actions: [
        if (total != null)
          MxButton(
            label: l10n.cardSelectAllCount(total),
            size: MxButtonSize.compact,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_selectAll(context, ref, request.query)),
          ),
      ],
    );
  }
}

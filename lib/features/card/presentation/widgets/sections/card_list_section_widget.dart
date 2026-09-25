import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/states/card_search_open_state.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_flag_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_sort_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_bulk_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_summary_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_empty_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// A deck's cards (screen 07, UC-CARD-001): the search the app bar reveals,
/// the deck summary, the filters, "Showing n of total" with the sort, then
/// one card per row. A long-press starts selection: the app bar turns into
/// the selection header (spec A14) and the bulk bar shows.
class CardListSectionWidget extends ConsumerStatefulWidget {
  const CardListSectionWidget({
    super.key,
    required this.deckId,
    required this.algorithm,
    required this.onAddCard,
    required this.onOpenCard,
  });

  final String deckId;

  /// The deck's scheduler, named, for the summary.
  final String algorithm;

  /// New card: the router opens the card editor.
  final VoidCallback onAddCard;

  /// A row tap outside selection: the router opens the card's detail.
  final ValueChanged<String> onOpenCard;

  @override
  ConsumerState<CardListSectionWidget> createState() =>
      _CardListSectionWidgetState();
}

class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
  static const int _skeletonRows = 4;

  /// How close to the end of the scroll a larger window is asked for.
  static const double _growWithin = 600;

  final _query = TextEditingController();

  /// Ruling P3-L5: the rows stay while a new window, filter or term loads.
  CardListView? _lastView;

  /// The window a growth was asked from, so one end of list asks once.
  int? _grownFrom;

  /// Ruling E-L6: the last Flag failed; the selection stays. Flag's sheet
  /// closes before the write, so the section says so; Move, Tag and Delete
  /// keep their overlay open and say it there.
  var _hasBulkFailed = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  CardListRequest _request() =>
      ref.read(cardListRequestProvider(widget.deckId).notifier);

  CardSelection _selection() =>
      ref.read(cardSelectionProvider(widget.deckId).notifier);

  void _growFrom(int windowSize) {
    if (_grownFrom == windowSize) return;
    _grownFrom = windowSize;
    _request().grow();
  }

  /// Other cards show, so the selection goes (IT-ORG-013).
  void _show(CardListFilter filter) {
    _request().show(filter);
    _selection().clear();
  }

  void _search(String term) {
    _request().search(term);
    _selection().clear();
  }

  /// Ruling P3-L4: set or clear, as chosen. The selection goes only once the
  /// write landed (IT-ORG-014); a failure keeps it and says so (E-L6).
  Future<void> _flag(Set<String> cardIds) async {
    setState(() => _hasBulkFailed = false);
    final isFlagged = await showCardFlagSheet(context);
    if (isFlagged == null || !mounted) return;
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .setFlagged(cardIds: cardIds, isFlagged: isFlagged);
      if (!mounted) return;
      final l10n = context.l10n;
      switch (outcome) {
        case Ok():
          _selection().clear();
          showMxSnackbar(
            context,
            message: isFlagged
                ? l10n.cardFlaggedToast(cardIds.length)
                : l10n.cardUnflaggedToast(cardIds.length),
          );
        case Rejected(:final reason):
          showMxSnackbar(context, message: l10n.cardRejection(reason));
      }
    } on Failure {
      if (!mounted) return;
      setState(() => _hasBulkFailed = true);
    }
  }

  /// Each overlay says its own outcome; the selection goes once the write
  /// landed. The section may be gone by then (the deck emptied), hence the
  /// `mounted` check.
  Future<void> _clearAfter(Future<bool> write) async {
    setState(() => _hasBulkFailed = false);
    if (await write && mounted) _selection().clear();
  }

  /// The bulk bar's commands over [selected]: Move, Flag, Tag, Delete.
  /// Export waits under Coming soon (spec A4, amended); Select all is in the
  /// app bar (spec A14).
  List<CardBulkAction> _bulkActions(Set<String> selected) {
    final l10n = context.l10n;
    return [
      (
        icon: AppIcons.folder,
        label: l10n.cardMove,
        onTap: () => unawaited(
          _clearAfter(
            showCardMoveSheet(
              context,
              sourceDeckId: widget.deckId,
              cardIds: selected,
            ),
          ),
        ),
      ),
      (
        icon: AppIcons.flag,
        label: l10n.cardFlag,
        onTap: () => unawaited(_flag(selected)),
      ),
      (
        icon: AppIcons.tag,
        label: l10n.cardTag,
        onTap: () => unawaited(
          _clearAfter(showCardTagDialog(context, cardIds: selected)),
        ),
      ),
      (
        icon: AppIcons.delete,
        label: l10n.cardDelete,
        onTap: () => unawaited(
          _clearAfter(showDeleteCardsDialog(context, cardIds: selected)),
        ),
      ),
    ];
  }

  void _sort(CardListRequestState request) => unawaited(
    showCardSortSheet(
      context,
      selected: request.sort,
      onSelected: (sort) => _request().sortBy(sort),
    ),
  );

  /// Closing the search clears its field as well as its term.
  void _onSearchOpen(bool? wasOpen, bool isOpen) {
    if (wasOpen == true && !isOpen) _query.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(cardSearchOpenProvider(widget.deckId), _onSearchOpen);
    final request = ref.watch(cardListRequestProvider(widget.deckId));
    final selected = ref.watch(cardSelectionProvider(widget.deckId));
    final isSelecting = selected.isNotEmpty;
    final isSearchOpen = ref.watch(cardSearchOpenProvider(widget.deckId));
    final provider = cardListProvider(
      deckId: widget.deckId,
      filter: request.filter,
      sort: request.sort,
      searchTerm: request.searchTerm,
      windowSize: request.windowSize,
    );
    final async = ref.watch(provider);
    // A failure always says so, even over rows loaded before (spec §5).
    if (async.hasError) {
      return MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.cardLoadErrorTitle,
            body: l10n.libraryLoadErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(provider),
          ),
        ],
      );
    }
    final view = _lastView = async.value ?? _lastView;
    if (view == null) {
      return MxScreenScroll(
        children: [
          MxSkeletonList(
            semanticLabel: context.l10n.commonLoading,
            rows: _skeletonRows,
          ),
        ],
      );
    }
    // A larger window is asked for only once the current one has loaded.
    final canGrow = async.hasValue && view.hasMore;
    // Back leaves selection before it leaves the deck (IT-ORG-013).
    return PopScope(
      canPop: !isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selection().clear();
      },
      child: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (canGrow &&
                    notification.depth == 0 &&
                    notification.metrics.extentAfter < _growWithin) {
                  _growFrom(request.windowSize);
                }
                return false;
              },
              // E-L5: each row is its own child, built only in view.
              child: MxScreenScroll(
                children: _children(view, request, selected, isSearchOpen),
              ),
            ),
          ),
          if (isSelecting && _hasBulkFailed)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: MxInlineBanner(
                tone: MxBannerTone.danger,
                title: l10n.cardBulkFailedTitle,
                message: l10n.cardBulkFailedBody,
              ),
            ),
          if (isSelecting) CardBulkBarWidget(actions: _bulkActions(selected)),
        ],
      ),
    );
  }

  /// The search, the summary and the filters (none while selecting), the
  /// header, then the rows or why none show.
  List<Widget> _children(
    CardListView view,
    CardListRequestState request,
    Set<String> selected,
    bool isSearchOpen,
  ) {
    final l10n = context.l10n;
    final isSelecting = selected.isNotEmpty;
    final total = view.counts.of(request.filter);
    return [
      const SizedBox(height: AppSpacing.control),
      // Selecting hides the field; its term stays and comes back with it.
      if (isSearchOpen && !isSelecting)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.grouped),
          child: MxSearchField(
            controller: _query,
            hintText: l10n.cardSearchHint,
            clearLabel: l10n.cardSearchClear,
            onChanged: _search,
          ),
        ),
      if (!isSelecting) ...[
        CardDeckSummaryWidget(view: view, algorithm: widget.algorithm),
        CardListToolbarWidget(
          request: request,
          counts: view.counts,
          onFilter: _show,
        ),
      ],
      MxListSectionHeader(
        label: isSelecting
            ? l10n.cardSelectedOf(selected.length, total)
            : l10n.cardShowingOf(view.items.length, total),
        trailing: isSelecting
            ? null
            : MxChipTrigger(
                label: l10n.cardSort(request.sort),
                icon: AppIcons.sort,
                onPressed: () => _sort(request),
              ),
      ),
      if (view.items.isEmpty)
        CardListEmptyWidget(
          request: request,
          total: view.statusCounts.total,
          onShowAll: () => _show(CardListFilter.all),
          onAddCard: widget.onAddCard,
        )
      else
        for (final item in view.items)
          CardRowWidget(
            // The summary and the filters step aside while selecting; the
            // key keeps each row's state (its ink) on its own card.
            key: ValueKey(item.id),
            item: item,
            isSelecting: isSelecting,
            isSelected: selected.contains(item.id),
            // BR-CARD-020: a tap opens the card; while selecting it only
            // toggles.
            onTap: isSelecting
                ? () => _selection().toggle(item.id)
                : () => widget.onOpenCard(item.id),
            onLongPress: () => _selection().toggle(item.id),
          ),
    ];
  }
}

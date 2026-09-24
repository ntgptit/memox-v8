import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_sort_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A deck's cards (spec §6.4): search, the filters with their counts, a
/// sort, and the rows of a window that grows as the list nears its end.
class CardListSectionWidget extends ConsumerStatefulWidget {
  const CardListSectionWidget({super.key, required this.deckId});

  final String deckId;

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

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  CardListRequest _request() =>
      ref.read(cardListRequestProvider(widget.deckId).notifier);

  void _growFrom(int windowSize) {
    if (_grownFrom == windowSize) return;
    _grownFrom = windowSize;
    _request().grow();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final request = ref.watch(cardListRequestProvider(widget.deckId));
    final provider = cardListProvider(
      deckId: widget.deckId,
      filter: request.filter,
      sort: request.sort,
      searchTerm: request.searchTerm,
      windowSize: request.windowSize,
    );
    final async = ref.watch(provider);
    final view = _lastView = async.value ?? _lastView;
    if (view == null) {
      return MxScreenScroll(
        children: [
          if (async.hasError)
            MxErrorState(
              title: l10n.cardLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            )
          else
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
        ],
      );
    }
    // A larger window is asked for only once the current one has loaded.
    final canGrow = async.hasValue && view.hasMore;
    final items = view.items;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (canGrow &&
            notification.depth == 0 &&
            notification.metrics.extentAfter < _growWithin) {
          _growFrom(request.windowSize);
        }
        return false;
      },
      child: MxScreenScroll(
        children: [
          CardListToolbarWidget(
            searchController: _query,
            request: request,
            counts: view.counts,
            onSearch: (term) => _request().search(term),
            onFilter: (filter) => _request().show(filter),
            onSort: () => unawaited(
              showCardSortSheet(
                context,
                selected: request.sort,
                onSelected: (sort) => _request().sortBy(sort),
              ),
            ),
          ),
          if (items.isEmpty)
            _CardListEmpty(
              request: request,
              onShowAll: () => _request().show(CardListFilter.all),
            )
          else
            // Ruling P3-L6: one card over the current window.
            MxCard(
              isFullBleed: true,
              child: Column(
                children: [
                  for (final (index, item) in items.indexed)
                    CardRowWidget(
                      item: item,
                      isSelecting: false,
                      isSelected: false,
                      hasDivider: index < items.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Why no row shows: a search, a filter, or an empty deck.
class _CardListEmpty extends StatelessWidget {
  const _CardListEmpty({required this.request, required this.onShowAll});

  final CardListRequestState request;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final term = request.searchTerm.trim();
    if (term.isNotEmpty) {
      return MxEmptyState(
        icon: AppIcons.search,
        title: l10n.cardSearchEmptyTitle(term),
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
      );
    }
    if (request.filter != CardListFilter.all) {
      return MxEmptyState(
        icon: AppIcons.filter,
        title: l10n.cardFilterEmptyTitle(l10n.cardFilter(request.filter)),
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
        actionLabel: l10n.cardShowAll,
        onAction: onShowAll,
      );
    }
    // Ruling P3-L3: "Add card" arrives with the editor in phase 4.
    return MxEmptyState(
      icon: AppIcons.inbox,
      title: l10n.cardEmptyTitle,
      body: l10n.cardEmptyBody,
    );
  }
}

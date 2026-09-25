import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// Why no row shows: a search or a filter with no hit. A deck left with no
/// card is unset again (ruling E-L1), so it never reaches this section.
class CardListEmptyWidget extends StatelessWidget {
  const CardListEmptyWidget({
    super.key,
    required this.request,
    required this.total,
    required this.onShowAll,
    required this.onAddCard,
  });

  final CardListRequestState request;

  /// Every card of the deck, for the search's way back.
  final int total;
  final VoidCallback onShowAll;
  final VoidCallback onAddCard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final term = request.searchTerm.trim();
    if (term.isNotEmpty) {
      return MxEmptyState(
        icon: AppIcons.search,
        title: l10n.cardSearchEmptyTitle(term),
        // Clearing the search keeps the filter: only under All does it
        // bring back the whole deck.
        body: request.filter == CardListFilter.all
            ? l10n.cardSearchEmptyBody(total)
            : l10n.cardSearchEmptyHint,
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
    return MxEmptyState(
      icon: AppIcons.inbox,
      title: l10n.cardEmptyTitle,
      body: l10n.cardEmptyBody,
      actionLabel: l10n.cardNewCard,
      onAction: onAddCard,
    );
  }
}

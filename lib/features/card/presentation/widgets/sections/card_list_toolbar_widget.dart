import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Search within the deck when the app bar opened it (E-O3), the four
/// filters with their counts, and the sort (screen 07). While selecting,
/// neither the search nor the filters show.
class CardListToolbarWidget extends StatelessWidget {
  const CardListToolbarWidget({
    super.key,
    required this.searchController,
    required this.searchFocus,
    required this.isSearchShown,
    required this.isFilterShown,
    required this.request,
    required this.counts,
    required this.onSearch,
    required this.onFilter,
    required this.onSort,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final bool isSearchShown;
  final bool isFilterShown;
  final CardListRequestState request;
  final CardListCounts counts;
  final ValueChanged<String> onSearch;
  final ValueChanged<CardListFilter> onFilter;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.control),
        if (isSearchShown) ...[
          MxSearchField(
            controller: searchController,
            focusNode: searchFocus,
            hintText: l10n.cardSearchHint,
            clearLabel: l10n.cardSearchClear,
            onChanged: onSearch,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
        // The chips never shrink or wrap, so their row scrolls.
        if (isFilterShown)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: AppSpacing.control,
              children: [
                for (final filter in CardListFilter.values)
                  MxFilterChip(
                    label: l10n.cardFilter(filter),
                    count: counts.of(filter),
                    isSelected: filter == request.filter,
                    onSelected: (_) => onFilter(filter),
                  ),
                MxChipTrigger(
                  label: l10n.cardSortTrigger(l10n.cardSort(request.sort)),
                  icon: AppIcons.sort,
                  onPressed: onSort,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.grouped),
      ],
    );
  }
}

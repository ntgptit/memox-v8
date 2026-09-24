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
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_unavailable.dart';

/// Above the rows (screen 07): the search the app bar opened (E-O3), the
/// deck's summary, the four filters with their counts and Tags (not yet),
/// then a header counting what shows, with the sort. While selecting, the
/// header counts the selection and nothing else shows (ruling E-L3).
class CardListToolbarWidget extends StatelessWidget {
  const CardListToolbarWidget({
    super.key,
    required this.searchController,
    required this.searchFocus,
    required this.isSearchShown,
    required this.isFilterShown,
    required this.summary,
    required this.shownCount,
    required this.selectedCount,
    required this.request,
    required this.counts,
    required this.onSearch,
    required this.onFilter,
    required this.onSort,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final bool isSearchShown;

  /// The filters, and the header when not selecting; off in a deck with no
  /// card.
  final bool isFilterShown;

  /// The deck's summary card, above the filters; null while selecting or
  /// when the deck holds no card.
  final Widget? summary;

  /// The rows loaded; the header's "Showing N".
  final int shownCount;

  /// The cards selected; zero when not selecting.
  final int selectedCount;
  final CardListRequestState request;
  final CardListCounts counts;
  final ValueChanged<String> onSearch;
  final ValueChanged<CardListFilter> onFilter;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = counts.of(request.filter);
    final isSelecting = selectedCount > 0;
    final isNoMatch = total == 0 && request.searchTerm.trim().isNotEmpty;
    final summary = this.summary;
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
        if (summary != null) ...[
          summary,
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
                    icon: filter == CardListFilter.flagged
                        ? AppIcons.flag
                        : null,
                    count: counts.of(filter),
                    isSelected: filter == request.filter,
                    onSelected: (_) => onFilter(filter),
                  ),
                // Spec A4: tags filtering waits for FE-B2.
                MxUnavailable(
                  hint: l10n.commonNotAvailableYet,
                  child: MxFilterChip(
                    label: l10n.cardFilterTags,
                    icon: AppIcons.tag,
                    isSelected: false,
                    onSelected: null,
                  ),
                ),
              ],
            ),
          ),
        if (isFilterShown || isSelecting)
          MxListSectionHeader(
            label: switch ((isSelecting, isNoMatch)) {
              (true, _) => l10n.cardListSelectedOf(selectedCount, total),
              (false, true) => l10n.cardListNoMatches,
              (false, false) => l10n.cardListShowing(shownCount, total),
            },
            trailing: isSelecting
                ? null
                : MxChipTrigger(
                    label: request.sort == CardListSort.newest
                        ? l10n.cardSortNewestPill
                        : l10n.cardSortDuePill,
                    onPressed: onSort,
                  ),
          ),
      ],
    );
  }
}

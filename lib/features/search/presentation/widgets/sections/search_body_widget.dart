import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';
import 'package:memox/features/search/presentation/widgets/sections/search_hints_widget.dart';
import 'package:memox/features/search/presentation/widgets/sections/search_results_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 04's body: one widget per [SearchScreenState] (spec D4, D14).
class SearchBodyWidget extends ConsumerWidget {
  const SearchBodyWidget({
    super.key,
    required this.onOpenDeck,
    required this.onOpenCard,
  });

  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String> onOpenCard;

  /// Two groups of three, as the kit draws the first read (spec D14).
  static const int _skeletonGroups = 2;
  static const int _skeletonRows = 3;
  static const double _skeletonHeaderWidth = 72;

  SearchScreenController _controller(WidgetRef ref) =>
      ref.read(searchScreenControllerProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return switch (ref.watch(searchScreenControllerProvider)) {
      SearchScreenIdle() => const SearchHintsWidget(),
      SearchScreenLoading(:final term) => MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          MxListSectionHeader(label: l10n.searchSearching(term)),
          for (var group = 0; group < _skeletonGroups; group++) ...[
            // The group header's place: a short bar, as the kit draws it.
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.control),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: MxSkeleton(width: _skeletonHeaderWidth),
              ),
            ),
            const MxCard(
              isFullBleed: true,
              child: MxSkeletonList(rows: _skeletonRows),
            ),
          ],
        ],
      ),
      final SearchScreenResults results => SearchResultsWidget(
        results: results,
        onOpenDeck: onOpenDeck,
        onOpenCard: onOpenCard,
        onLoadMore: () => _controller(ref).loadMore(),
        onRetry: () => _controller(ref).retry(),
      ),
      SearchScreenNoResults(:final term) => MxScreenScroll(
        children: [
          MxEmptyState(
            icon: AppIcons.searchOff,
            title: l10n.searchNoMatchesTitle(term),
            body: l10n.searchNoMatchesBody,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      ),
      SearchScreenFailed() => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.searchErrorTitle,
            body: l10n.searchErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => _controller(ref).retry(),
          ),
        ],
      ),
    };
  }
}

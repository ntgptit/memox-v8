import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_row_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_header_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// A loaded level: today's work first, then the decks (spec §6.1, D3).
class DeckLevelListWidget extends ConsumerWidget {
  const DeckLevelListWidget({
    super.key,
    required this.level,
    required this.onCreateDeck,
  });

  final DeckLevel level;
  final VoidCallback onCreateDeck;

  void _showAll(WidgetRef ref) =>
      ref.read(deckLevelQueryProvider(null).notifier).show(DeckLevelFilter.all);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(deckLevelQueryProvider(null)).filter;
    final tiles = level.tiles;
    // Ruling L4: an empty level is the first run; an empty filter is not.
    if (tiles.isEmpty && filter == DeckLevelFilter.all) {
      return MxScreenScroll(
        clearance: MxScrollClearance.fabAboveNav,
        children: [
          const SizedBox(height: AppSpacing.gutter),
          MxEmptyState(
            icon: AppIcons.library,
            title: l10n.libraryEmptyTitle,
            body: l10n.libraryEmptyBody,
            actionLabel: l10n.libraryCreateDeck,
            onAction: onCreateDeck,
          ),
        ],
      );
    }
    return MxScreenScroll(
      clearance: MxScrollClearance.fabAboveNav,
      children: [
        const SizedBox(height: AppSpacing.gutter),
        DeckWorkloadLineWidget(
          overdueCount: level.overdueCount,
          todayCount: level.dueTodayCount,
          newCount: level.newCount,
          cardCount:
              level.overdueCount +
              level.dueTodayCount +
              level.newCount +
              level.scheduledCount,
        ),
        const SizedBox(height: AppSpacing.section),
        const DeckLevelHeaderWidget(),
        if (tiles.isEmpty)
          MxEmptyState(
            icon: AppIcons.library,
            title: l10n.libraryNothingDueTitle,
            body: l10n.libraryNothingDueBody,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
            actionLabel: l10n.libraryShowAllDecks,
            onAction: () => _showAll(ref),
          )
        else
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, tile) in tiles.indexed)
                  DeckRowWidget(
                    tile: tile,
                    hasDivider: index < tiles.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_row_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_due_strip_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_header_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// A loaded level: today's work first, then the decks (spec §6.1, D3).
class DeckLevelListWidget extends ConsumerWidget {
  const DeckLevelListWidget({
    super.key,
    required this.level,
    required this.parentId,
    required this.onOpenDeck,
    required this.onOpenAlgorithm,
    required this.onOpenStudy,
    required this.emptyState,
    required this.schedulerType,
    required this.hasDeepestSubDecks,
  });

  final DeckLevel level;
  final String? parentId;
  final ValueChanged<String> onOpenDeck;

  /// A root's review algorithm (screen 02), from a row's action sheet.
  final ValueChanged<String> onOpenAlgorithm;

  /// A deck's Study Entry (screen 14), from an action sheet or a summary.
  final ValueChanged<String> onOpenStudy;

  /// Shown when the level holds no deck at all (ruling L4).
  final Widget emptyState;

  /// The open deck's algorithm for its summary card; null at the root.
  final SchedulerType? schedulerType;

  /// The open deck's sub-decks sit at [DeckEntity.maxDepth]: the header
  /// names that level (owner decision C-O6).
  final bool hasDeepestSubDecks;

  bool get _hasCards =>
      level.overdueCount +
          level.dueTodayCount +
          level.newCount +
          level.scheduledCount >
      0;

  /// "6 decks" at the root, "4 sub-decks" in a deck, or the filter's
  /// heading whichever level it is.
  String _headerLabel(AppLocalizations l10n, DeckLevelFilter filter) {
    if (filter == DeckLevelFilter.due) return l10n.libraryDueDecksHeader;
    if (parentId == null) return l10n.libraryDecksCount(level.deckCount);
    if (hasDeepestSubDecks) return l10n.deckDepthHeader(level.deckCount);
    return l10n.deckSubDeckCount(level.deckCount);
  }

  void _showAll(WidgetRef ref) => ref
      .read(deckLevelQueryProvider(parentId).notifier)
      .show(DeckLevelFilter.all);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(deckLevelQueryProvider(parentId)).filter;
    final tiles = level.tiles;
    // Ruling L4: an empty level is the first run; an empty filter is not.
    if (tiles.isEmpty && filter == DeckLevelFilter.all) {
      return MxScreenScroll(
        clearance: MxScrollClearance.fabAboveNav,
        children: [
          const SizedBox(height: AppSpacing.gutter),
          emptyState,
        ],
      );
    }
    return MxScreenScroll(
      clearance: MxScrollClearance.fabAboveNav,
      children: [
        // Screen 01: the strip or the summary sits close under the search
        // field or the breadcrumb, whose own inset is the gap.
        if ((parentId, schedulerType) case (
          final deckId?,
          final algorithm?,
        )) ...[
          DeckSummaryCardWidget(
            level: level,
            schedulerType: algorithm,
            onStudy: () => onOpenStudy(deckId),
          ),
          const SizedBox(height: AppSpacing.grouped),
        ] else if (_hasCards) ...[
          DeckDueStripWidget(level: level),
          const SizedBox(height: AppSpacing.grouped),
        ],
        DeckLevelHeaderWidget(
          parentId: parentId,
          label: _headerLabel(l10n, filter),
        ),
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
          Column(
            spacing: AppSpacing.control,
            children: [
              for (final tile in tiles)
                DeckRowWidget(
                  tile: tile,
                  onTap: () => onOpenDeck(tile.id),
                  onMore: () => unawaited(
                    openDeckActions(
                      context,
                      ref,
                      deckId: tile.id,
                      parentId: parentId,
                      onOpenDeck: onOpenDeck,
                      onOpenAlgorithm: onOpenAlgorithm,
                      onOpenStudy: onOpenStudy,
                      isOpenDeck: false,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

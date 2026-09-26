import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/states/deck_reorder_mode_state.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_list_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_reorder_list_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A level's decks as its stream delivers them (spec §5): skeleton rows
/// while loading, a plain error with Retry, then the list. The roots are
/// [parentId] null.
class DeckLevelBodyWidget extends ConsumerWidget {
  const DeckLevelBodyWidget({
    super.key,
    required this.parentId,
    required this.onOpenDeck,
    required this.onOpenAlgorithm,
    required this.onOpenStudy,
    required this.emptyState,
    required this.schedulerType,
    required this.hasDeepestSubDecks,
    this.onOpenTrash,
  });

  final String? parentId;
  final ValueChanged<String> onOpenDeck;

  /// A root's review algorithm (screen 02), from a row's action sheet.
  final ValueChanged<String> onOpenAlgorithm;

  /// A deck's Study Entry (screen 14), from an action sheet or a summary.
  final ValueChanged<String> onOpenStudy;

  /// Opens the Trash (screen 06), for a refused Undo (FE-B1).
  final VoidCallback? onOpenTrash;

  /// The open deck's algorithm for its summary card; null at the root.
  final SchedulerType? schedulerType;

  /// The open deck's sub-decks sit at [DeckEntity.maxDepth]: none of them
  /// can hold a sub-deck.
  final bool hasDeepestSubDecks;

  /// Shown when the level holds no deck at all.
  final Widget emptyState;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider(parentId));
    final provider = deckLevelProvider(
      parentId: parentId,
      sort: query.sort,
      filter: query.filter,
    );
    final isReordering = ref.watch(deckReorderModeProvider(parentId));
    return ref
        .watch(provider)
        .when(
          data: (level) => isReordering
              ? DeckReorderListWidget(tiles: level.tiles)
              : DeckLevelListWidget(
                  level: level,
                  parentId: parentId,
                  onOpenDeck: onOpenDeck,
                  onOpenAlgorithm: onOpenAlgorithm,
                  onOpenStudy: onOpenStudy,
                  onOpenTrash: onOpenTrash,
                  emptyState: emptyState,
                  schedulerType: schedulerType,
                  hasDeepestSubDecks: hasDeepestSubDecks,
                ),
          loading: () => MxScreenScroll(
            clearance: MxScrollClearance.fabAboveNav,
            children: [
              MxSkeletonList(
                semanticLabel: context.l10n.commonLoading,
                rows: _skeletonRows,
              ),
            ],
          ),
          error: (_, _) => MxScreenScroll(
            clearance: MxScrollClearance.fabAboveNav,
            children: [
              MxErrorState(
                title: l10n.libraryLoadErrorTitle,
                body: l10n.libraryLoadErrorBody,
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(provider),
              ),
            ],
          ),
        );
  }
}

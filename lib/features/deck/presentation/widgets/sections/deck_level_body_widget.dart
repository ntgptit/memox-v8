import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_list_widget.dart';
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
    required this.emptyState,
  });

  final String? parentId;
  final ValueChanged<String> onOpenDeck;

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
    return ref
        .watch(provider)
        .when(
          data: (level) => DeckLevelListWidget(
            level: level,
            parentId: parentId,
            onOpenDeck: onOpenDeck,
            emptyState: emptyState,
          ),
          loading: () => MxScreenScroll(
            clearance: MxScrollClearance.fabAboveNav,
            children: [
              for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
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

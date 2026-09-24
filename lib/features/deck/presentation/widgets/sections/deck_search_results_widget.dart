import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/presentation/providers/deck_search_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_path_label_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The decks whose name holds [term], each under its path so two decks of
/// one name tell apart (IT-DISC-006).
class DeckSearchResultsWidget extends ConsumerWidget {
  const DeckSearchResultsWidget({
    super.key,
    required this.term,
    required this.onOpenDeck,
  });

  final String term;
  final ValueChanged<String> onOpenDeck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A blank term searches nothing (IT-DISC-007), so nothing shows.
    if (term.trim().isEmpty) return const SizedBox.shrink();
    final provider = deckSearchProvider(term);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) when value.isEmpty => MxScreenScroll(
        children: [
          MxEmptyState(
            icon: AppIcons.search,
            title: l10n.deckSearchEmptyTitle(term.trim()),
            body: l10n.deckSearchEmptyBody,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      ),
      AsyncData(:final value) => MxScreenScroll(
        children: [
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, hit) in value.indexed)
                  MxListRow(
                    title: hit.name,
                    subtitle: hit.path.isEmpty
                        ? null
                        : deckPathLabel([
                            for (final entry in hit.path) entry.name,
                          ]),
                    leading: const MxIconTile(icon: AppIcons.library),
                    hasChevron: true,
                    onTap: () => onOpenDeck(hit.id),
                    hasDivider: index < value.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
      AsyncError() => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.libraryLoadErrorTitle,
            body: l10n.libraryLoadErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(provider),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

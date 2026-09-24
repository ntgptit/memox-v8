import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/providers/deck_search_provider.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_search_hit_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// The Library search's body (screen 04): what search finds while the term
/// is blank, then the decks whose name holds [term], each under its path so
/// two decks of one name tell apart (IT-DISC-006). Decks only (spec A11).
class DeckSearchResultsWidget extends ConsumerWidget {
  const DeckSearchResultsWidget({
    super.key,
    required this.term,
    required this.onOpenDeck,
  });

  final String term;
  final ValueChanged<String> onOpenDeck;

  static const int _skeletonRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trimmed = term.trim();
    // A blank term searches nothing (IT-DISC-007): say what search finds.
    if (trimmed.isEmpty) return const _SearchHintsWidget();
    final provider = deckSearchProvider(term);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) when value.isEmpty => MxScreenScroll(
        children: [
          MxEmptyState(
            icon: AppIcons.search,
            title: l10n.deckSearchEmptyTitle(trimmed),
            body: l10n.deckSearchEmptyBody,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      ),
      AsyncData(:final value) => MxScreenScroll(
        children: [
          MxListSectionHeader(label: l10n.searchResultsFor(trimmed)),
          MxListSectionHeader(
            label: l10n.searchDecksGroup,
            trailing: MxBadge(
              label: l10n.searchGroupCount(value.length),
              tone: MxBadgeTone.neutral,
            ),
          ),
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, hit) in value.indexed)
                  DeckSearchHitRowWidget(
                    hit: hit,
                    term: term,
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
            title: l10n.searchErrorTitle,
            body: l10n.searchErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(provider),
          ),
        ],
      ),
      _ => MxScreenScroll(
        children: [
          MxListSectionHeader(label: l10n.searchSearching(trimmed)),
          for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
        ],
      ),
    };
  }
}

/// What search finds, before a term: deck names, and a word on accents.
/// The card and tag hints wait for BE-A8 (spec A11).
class _SearchHintsWidget extends StatelessWidget {
  const _SearchHintsWidget();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxScreenScroll(
      children: [
        MxListSectionHeader(label: l10n.searchFinds),
        MxCard(
          isFullBleed: true,
          child: MxListRow(
            title: l10n.searchHintDeckName,
            subtitle: l10n.searchHintDeckExample,
            leading: const MxIconTile(icon: AppIcons.library),
            hasDivider: false,
          ),
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.searchAccentNote),
      ],
    );
  }
}

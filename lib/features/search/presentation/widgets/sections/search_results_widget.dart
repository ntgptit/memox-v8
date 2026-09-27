import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';
import 'package:memox/features/search/presentation/widgets/items/search_card_hit_row_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/search_deck_hit_row_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/search_load_more_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The hits of a term, decks first (BR-SEARCH-005). A group with no row has
/// no header (A2); only the last group drawn counts with "+" while a page
/// follows, since that page continues it (spec D10).
class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({
    super.key,
    required this.results,
    required this.onOpenDeck,
    required this.onOpenCard,
    required this.onLoadMore,
    required this.onRetry,
  });

  final SearchScreenResults results;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String> onOpenCard;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final decks = results.decks;
    final cards = results.cards;
    final isMoreOnCards = results.hasMore && cards.isNotEmpty;
    final isMoreOnDecks = results.hasMore && cards.isEmpty;
    String count(int rows, {required bool isMore}) =>
        isMore ? l10n.searchGroupCountMore(rows) : l10n.searchGroupCount(rows);
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        MxListSectionHeader(label: l10n.searchResultsFor(results.term)),
        if (decks.isNotEmpty) ...[
          MxListSectionHeader(
            label: l10n.searchDecksGroup,
            trailing: MxBadge(
              label: count(decks.length, isMore: isMoreOnDecks),
              tone: MxBadgeTone.neutral,
            ),
          ),
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, hit) in decks.indexed)
                  SearchDeckHitRowWidget(
                    hit: hit,
                    term: results.term,
                    onTap: () => onOpenDeck(hit.deckId),
                    hasDivider: index < decks.length - 1,
                  ),
              ],
            ),
          ),
        ],
        if (cards.isNotEmpty) ...[
          if (decks.isNotEmpty) const SizedBox(height: AppSpacing.grouped),
          MxListSectionHeader(
            label: l10n.searchCardsGroup,
            trailing: MxBadge(
              label: count(cards.length, isMore: isMoreOnCards),
              tone: MxBadgeTone.neutral,
            ),
          ),
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, hit) in cards.indexed)
                  SearchCardHitRowWidget(
                    hit: hit,
                    term: results.term,
                    onTap: () => onOpenCard(hit.cardId),
                    hasDivider: index < cards.length - 1,
                  ),
              ],
            ),
          ),
        ],
        if (results.hasMore || results.more == SearchMoreStatus.failed) ...[
          const SizedBox(height: AppSpacing.grouped),
          SearchLoadMoreWidget(
            status: results.more,
            onLoadMore: onLoadMore,
            onRetry: onRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.grouped),
        Text(
          l10n.searchFooter,
          textAlign: TextAlign.center,
          style: context.textStyles.footerCaption,
        ),
      ],
    );
  }
}

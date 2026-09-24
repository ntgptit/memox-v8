import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// One deck of a level (screen 01): a card with the deck's tile, its name,
/// "N due" when cards wait, what it holds, and ⋮ for its commands. A tap
/// anywhere else opens it.
class DeckRowWidget extends StatelessWidget {
  const DeckRowWidget({
    super.key,
    required this.tile,
    required this.onTap,
    required this.onMore,
  });

  final DeckTile tile;
  final VoidCallback onTap;
  final VoidCallback onMore;

  IconData get _glyph => switch (tile) {
    DeckTile(subDeckCount: > 0) => AppIcons.library,
    DeckTile(cardCount: > 0) => AppIcons.cardDeck,
    _ => AppIcons.folder,
  };

  /// "4 sub-decks · 1,248 cards", "420 cards" for a deck of cards, or the
  /// empty line (screen 01).
  String _meta(AppLocalizations l10n) => switch (tile) {
    DeckTile(subDeckCount: 0, cardCount: 0) => l10n.deckRowEmpty,
    DeckTile(subDeckCount: 0) => l10n.deckCardCount(tile.cardCount),
    _ => l10n.deckRowMeta(
      l10n.deckSubDeckCount(tile.subDeckCount),
      l10n.deckCardCount(tile.cardCount),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxCard(
      isFullBleed: true,
      child: MxRowInk(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.gutter,
            AppSpacing.micro,
            AppSpacing.gutter,
          ),
          child: Row(
            spacing: AppSpacing.gutter,
            children: [
              MxIconTile(icon: _glyph, size: MxIconTileSize.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.micro,
                  children: [
                    Row(
                      spacing: AppSpacing.control,
                      children: [
                        Expanded(
                          child: Text(
                            tile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.rowTitle,
                          ),
                        ),
                        if (tile.dueCount > 0)
                          MxBadge(label: l10n.deckDueBadge(tile.dueCount)),
                      ],
                    ),
                    Text(
                      _meta(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.rowSubtitle,
                    ),
                  ],
                ),
              ),
              MxIconButton(
                icon: AppIcons.more,
                semanticLabel: l10n.deckMoreActions(tile.name),
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

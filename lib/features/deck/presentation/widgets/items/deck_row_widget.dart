import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmpty = tile.subDeckCount == 0 && tile.cardCount == 0;
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
                      isEmpty
                          ? l10n.deckRowEmpty
                          : l10n.deckRowMeta(
                              l10n.deckSubDeckCount(tile.subDeckCount),
                              l10n.deckCardCount(tile.cardCount),
                            ),
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

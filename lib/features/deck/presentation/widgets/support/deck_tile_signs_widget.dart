import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// What a deck's row says of its contents (screen 01's tile legend): layers
/// for a deck that holds decks, the copy glyph for one that holds cards, the
/// open folder for an empty one. Browse and reorder rows read the same
/// signs for the same deck (ruling M3-D2; DEV-232).
IconData deckTileGlyph(DeckTile tile) => switch (tile) {
  DeckTile(subDeckCount: > 0) => AppIcons.library,
  DeckTile(cardCount: > 0) => AppIcons.cardDeck,
  _ => AppIcons.folder,
};

/// The structure line under the name: "4 sub-decks · 1,248 cards", "420
/// cards" for a deck of cards, or the empty line (screen 01).
String deckTileMeta(DeckTile tile, AppLocalizations l10n) => switch (tile) {
  DeckTile(subDeckCount: 0, cardCount: 0) => l10n.deckRowEmpty,
  DeckTile(subDeckCount: 0) => l10n.deckCardCount(tile.cardCount),
  _ => l10n.deckRowMeta(
    l10n.deckSubDeckCount(tile.subDeckCount),
    l10n.deckCardCount(tile.cardCount),
  ),
};

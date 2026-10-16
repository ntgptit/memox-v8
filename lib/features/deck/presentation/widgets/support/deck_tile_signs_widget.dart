import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/meta_line.dart';

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
/// cards" for a deck of cards, or the empty line (screen 01). The counts
/// wrap only between whole terms (The Wrap Rule); the empty line is a hint,
/// which wraps as words with its dot kept on the word before it.
String deckTileMeta(DeckTile tile, AppLocalizations l10n) => switch (tile) {
  DeckTile(subDeckCount: 0, cardCount: 0) => metaDots(l10n.deckRowEmpty),
  DeckTile(subDeckCount: 0) => wholeTerm(l10n.deckCardCount(tile.cardCount)),
  _ => deckStructureLine(
    l10n,
    subDecks: tile.subDeckCount,
    cards: tile.cardCount,
  ),
};

/// "4 sub-decks · 1,248 cards", wrapping only between its two terms: a
/// deck row's line and the summary card's (screen 01).
String deckStructureLine(
  AppLocalizations l10n, {
  required int subDecks,
  required int cards,
}) => metaLine(
  l10n.deckRowMeta(l10n.deckSubDeckCount(subDecks), l10n.deckCardCount(cards)),
);

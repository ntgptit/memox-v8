/// Route paths. The four top-level branches are in bottom-nav order
/// (navigation.md); the app opens on [decks].
abstract final class AppRoutes {
  static const String decks = '/decks';
  static const String study = '/study';
  static const String progress = '/progress';
  static const String settings = '/settings';

  /// Debug builds only: the component gallery.
  static const String gallery = '/gallery';

  /// The path parameter that names an open deck.
  static const String deckIdParam = 'deckId';

  /// The Library's child routes (library spec §4), relative to [decks].
  static const String deckChild = 'deck/:$deckIdParam';
  static const String searchChild = 'search';

  static const String deckSearch = '$decks/$searchChild';

  /// A root deck's review algorithm (screen 02), relative to [deckChild].
  static const String algorithmChild = 'algorithm';

  /// A deck's card editor in create mode, relative to [deckChild].
  static const String cardNewChild = 'cards/new';

  /// A deck's card import (kit 11, IT-NAV-012), relative to [deckChild].
  static const String cardImportChild = 'cards/import';

  /// The path parameter that names a card.
  static const String cardIdParam = 'cardId';

  /// A card's detail, relative to [decks], and its editor, relative to it.
  static const String cardChild = 'card/:$cardIdParam';
  static const String cardEditChild = 'edit';

  /// An open deck's location.
  static String deck(String deckId) => '$decks/deck/$deckId';

  /// Screen 02 for the root [deckId].
  static String deckAlgorithm(String deckId) =>
      '${deck(deckId)}/$algorithmChild';

  /// The card editor adding cards to [deckId].
  static String newCard(String deckId) => '${deck(deckId)}/$cardNewChild';

  /// The card import into [deckId].
  static String importCards(String deckId) =>
      '${deck(deckId)}/$cardImportChild';

  /// A card's detail.
  static String card(String cardId) => '$decks/card/$cardId';

  /// The card editor for [cardId].
  static String editCard(String cardId) => '${card(cardId)}/$cardEditChild';
}

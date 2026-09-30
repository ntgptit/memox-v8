/// Route paths. The four top-level branches are in bottom-nav order
/// (navigation.md); the app opens on [decks].
abstract final class AppRoutes {
  static const String decks = '/decks';
  static const String study = '/study';
  static const String progress = '/progress';
  static const String settings = '/settings';

  /// The path parameter that names a study session.
  static const String sessionIdParam = 'sessionId';

  /// A study session, full screen on the root navigator (FE-A6 D2).
  static const String studySessionPath = '$study/session/:$sessionIdParam';

  /// The theme (screen 25), relative to [settings]: a full-screen page on
  /// the root navigator, as the kit draws it (FE-A3 D2).
  static const String settingsThemeChild = 'theme';
  static const String settingsTheme = '$settings/$settingsThemeChild';

  /// The language (screen 26), relative to [settings], on the root
  /// navigator.
  static const String settingsLanguageChild = 'language';
  static const String settingsLanguage = '$settings/$settingsLanguageChild';

  /// The daily reminder (screen 24), relative to [settings], on the root
  /// navigator like Theme and Language (FE-B5 spec D5).
  static const String settingsReminderChild = 'reminder';
  static const String settingsReminder = '$settings/$settingsReminderChild';

  /// Sync (screen 27, SB-U1), relative to [settings], on the root
  /// navigator like Theme and Language.
  static const String settingsSyncChild = 'sync';
  static const String settingsSync = '$settings/$settingsSyncChild';

  /// Monitoring (screen 28, ADR-018 §8), relative to [settings]: an admin's
  /// page on the root navigator like Sync, and one log's detail under it.
  static const String settingsMonitoringChild = 'monitoring';
  static const String settingsMonitoring = '$settings/$settingsMonitoringChild';

  /// The path parameter that names a log, and the query parameter that says
  /// it is read from the device buffer (`?local=1`).
  static const String monitoringLogIdParam = 'logId';
  static const String monitoringLocalParam = 'local';
  static const String monitoringLogChild = ':$monitoringLogIdParam';
  static const String _monitoringLocalOn = '1';

  /// One log's detail, from the server or, when [isLocal], the buffer.
  static String settingsMonitoringLog(String logId, {bool isLocal = false}) =>
      Uri(
        path: '$settingsMonitoring/$logId',
        queryParameters: isLocal
            ? {monitoringLocalParam: _monitoringLocalOn}
            : null,
      ).toString();

  /// Whether [query] asks for the device buffer.
  static bool isLocalLog(Map<String, String> query) =>
      query[monitoringLocalParam] == _monitoringLocalOn;

  /// The first-launch Welcome (screen 29, account UI spec §4) and the
  /// location the launch was headed to.
  static const String welcome = '/welcome';
  static const String welcomeFromParam = 'from';

  static String welcomeFrom(String location) => Uri(
    path: welcome,
    queryParameters: {welcomeFromParam: location},
  ).toString();

  /// Attaching an account (screens 30 and 31), relative to [settings] on
  /// the root navigator like Sync (P3a plan ruling 1). The mode names the
  /// flow: `link` attaches an account, `reauth` signs in again.
  static const String settingsSignInChild = 'sign-in';
  static const String settingsSignIn = '$settings/$settingsSignInChild';
  static const String settingsSignInCodeChild = 'code';
  static const String settingsSignInCode =
      '$settingsSignIn/$settingsSignInCodeChild';
  static const String accountModeParam = 'mode';
  static const String accountEmailParam = 'email';
  static const String accountLinkMode = 'link';
  static const String settingsSignInLink =
      '$settingsSignIn?$accountModeParam=$accountLinkMode';

  static String settingsSignInCodeLink(String email) => Uri(
    path: settingsSignInCode,
    queryParameters: {
      accountModeParam: accountLinkMode,
      accountEmailParam: email,
    },
  ).toString();

  /// Screen 32 (account UI spec §5.6), under [settings] like Sync.
  static const String settingsAccountChild = 'account';
  static const String settingsAccount = '$settings/$settingsAccountChild';

  /// Screen 33, the admin's Users (users spec U5), under [settings].
  static const String settingsUsersChild = 'users';
  static const String settingsUsers = '$settings/$settingsUsersChild';

  /// Signing in again (spec §5.2) and where the flow began, to return to
  /// once it succeeds (spec §9 B9).
  static const String accountReauthMode = 'reauth';
  static const String accountFromParam = 'from';

  static String settingsSignInReauth({required String from}) => Uri(
    path: settingsSignIn,
    queryParameters: {
      accountModeParam: accountReauthMode,
      accountFromParam: from,
    },
  ).toString();

  static String settingsSignInCodeReauth(
    String email, {
    required String from,
  }) => Uri(
    path: settingsSignInCode,
    queryParameters: {
      accountModeParam: accountReauthMode,
      accountEmailParam: email,
      accountFromParam: from,
    },
  ).toString();

  /// Debug builds only: the component gallery.
  static const String gallery = '/gallery';

  /// The path parameter that names an open deck.
  static const String deckIdParam = 'deckId';

  /// The Library's child routes (library spec §4), relative to [decks].
  static const String deckChild = 'deck/:$deckIdParam';
  static const String searchChild = 'search';

  static const String deckSearch = '$decks/$searchChild';

  /// The search's term on arrival, as a query parameter (FE-B2 spec D11).
  static const String searchQueryParam = 'q';

  /// The search, opened on [term].
  static String searchFor(String term) => Uri(
    path: deckSearch,
    queryParameters: {searchQueryParam: term},
  ).toString();

  /// The Trash (screen 06), relative to [decks]: a full-screen task on the
  /// root navigator (FE-B1 D2).
  static const String trashChild = 'trash';
  static const String trash = '$decks/$trashChild';

  /// Starter decks (screen 03) and Tags (screen 05), relative to [decks]:
  /// full-screen pages on the root navigator, as the kit draws them and as
  /// the Trash is (FE-B2 + FE-B4 spec D5).
  static const String starterDecksChild = 'starter';
  static const String starterDecks = '$decks/$starterDecksChild';
  static const String tagsChild = 'tags';
  static const String tags = '$decks/$tagsChild';

  /// A root deck's review algorithm (screen 02), relative to [deckChild].
  static const String algorithmChild = 'algorithm';

  /// A deck's Study Entry (screen 14), relative to [deckChild] (FE-A6 D1).
  static const String studyChild = 'study';

  /// A deck's study options (screen 15), relative to [deckChild] (FE-A3).
  static const String studyOptionsChild = 'options';

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

  /// Screen 14 for [deckId].
  static String studyEntry(String deckId) => '${deck(deckId)}/$studyChild';

  /// Screen 15 for [deckId], whose options are its root's.
  static String studyOptions(String deckId) =>
      '${deck(deckId)}/$studyOptionsChild';

  /// A deck's Progress level (screen 22), relative to [progress]: one page
  /// per level, under the tab bar (FE-A9 D5).
  static const String progressDeckChild = ':$deckIdParam';

  /// [deckId]'s Progress level.
  static String progressDeck(String deckId) => '$progress/$deckId';

  /// The session [sessionId], its summary once it has ended.
  static String studySession(String sessionId) => '$study/session/$sessionId';

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

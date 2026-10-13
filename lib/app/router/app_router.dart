import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/gallery/gallery_screen.dart';
import 'package:memox/app/router/account_routes.dart';
import 'package:memox/app/router/admin_routes.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/app/router/app_tab_shell.dart';
import 'package:memox/app/router/log_navigator_observer.dart';
import 'package:memox/app/router/route_not_found_screen.dart';
import 'package:memox/app/router/study_route_screens.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:memox/features/settings/presentation/widgets/items/sql_log_row_widget.dart';
import 'package:memox/features/reminders/presentation/providers/reset_app_options_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_add_fab_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_breadcrumb_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/settings/presentation/screens/language_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/settings/presentation/screens/study_defaults_screen.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The app's routes: four top-level branches in a stateful shell, each
/// keeping its own stack, plus the component gallery when [hasGallery]
/// (debug builds by default, so release builds never register it), and
/// Welcome and the account's attach flow (account UI spec §4), with the
/// redirect `app.dart` passes.
GoRouter buildAppRouter({
  bool hasGallery = kDebugMode,
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
  // The root navigator: a route on it covers the shell and its bottom bar.
  final rootNavigator = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigator,
    // ADR-018: navigation is logged; each branch's navigator has its own.
    observers: [LogNavigatorObserver()],
    initialLocation: AppRoutes.decks,
    refreshListenable: refreshListenable,
    redirect: redirect,
    // IT-NAV-005, FE-D3 spec D5: not go_router's page, which prints the error.
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppTabShell(navigationShell: navigationShell),
        branches: [
          // The Library (library spec §4): one page per deck level.
          StatefulShellBranch(
            observers: [LogNavigatorObserver()],
            routes: [
              GoRoute(
                path: AppRoutes.decks,
                builder: (context, state) => _deckLevel(context),
                routes: [
                  GoRoute(
                    path: AppRoutes.deckChild,
                    builder: (context, state) => _deckLevel(
                      context,
                      deckId: state.pathParameters[AppRoutes.deckIdParam],
                    ),
                    routes: [
                      GoRoute(
                        path: AppRoutes.cardNewChild,
                        builder: (context, state) => CardEditorScreen.create(
                          deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                          deckContext: _deckContext,
                          onOpenTrash: _openTrash(context),
                        ),
                      ),
                      // A full-screen task above the shell: no bottom bar
                      // (IT-NAV-012 step 1).
                      GoRoute(
                        path: AppRoutes.cardImportChild,
                        parentNavigatorKey: rootNavigator,
                        builder: (context, state) => CardImportScreen(
                          deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                          deckContext: _deckContext,
                          onClose: () => context.pop(),
                          onViewCards: () => context.pop(),
                        ),
                      ),
                      GoRoute(
                        path: AppRoutes.studyChild,
                        builder: (context, state) => studyEntryScreen(
                          context,
                          state.pathParameters[AppRoutes.deckIdParam]!,
                        ),
                      ),
                      // A full-screen task above the shell, as the kit
                      // draws it (FE-A3 spec §4).
                      GoRoute(
                        path: AppRoutes.studyOptionsChild,
                        parentNavigatorKey: rootNavigator,
                        builder: (context, state) => studyOptionsScreen(
                          context,
                          state.pathParameters[AppRoutes.deckIdParam]!,
                        ),
                      ),
                      GoRoute(
                        path: AppRoutes.algorithmChild,
                        builder: (context, state) => DeckAlgorithmScreen(
                          deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                          onOpenAncestor: (id) => _openAncestor(context, id),
                        ),
                      ),
                    ],
                  ),
                  // A full-screen task above the shell: no bottom bar
                  // (FE-B1 D2).
                  GoRoute(
                    path: AppRoutes.trashChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const TrashScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.starterDecksChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) =>
                        _starterDecks(context, rootNavigator),
                  ),
                  GoRoute(
                    path: AppRoutes.tagsChild,
                    parentNavigatorKey: rootNavigator,
                    // The search lives in the Library branch, under the
                    // shell: Find cards goes there, and Back returns to the
                    // Library (plan C-ruling on D11).
                    builder: (context, state) => TagsScreen(
                      onFindCards: (name) =>
                          context.go(AppRoutes.searchFor(name)),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.searchChild,
                    builder: (context, state) => LibrarySearchScreen(
                      initialQuery:
                          state.uri.queryParameters[AppRoutes
                              .searchQueryParam] ??
                          '',
                      onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
                      onOpenCard: (id) => context.push(AppRoutes.card(id)),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.cardChild,
                    builder: (context, state) => CardDetailScreen(
                      cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                      deckContext: _deckContext,
                      onEdit: (id) => unawaited(_editCard(context, id)),
                      onOpenTrash: _openTrash(context),
                    ),
                    routes: [
                      GoRoute(
                        path: AppRoutes.cardEditChild,
                        builder: (context, state) => CardEditorScreen.edit(
                          cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                          deckContext: _deckContext,
                          onOpenTrash: _openTrash(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [LogNavigatorObserver()],
            routes: [
              GoRoute(
                path: AppRoutes.study,
                // Screen 13 (FE-A8): a deck, the Library and the Starter
                // Library open in the Library branch, as the summary's "Study
                // this deck" does.
                builder: (context, state) => StudyHomeScreen(
                  onOpenSession: (sessionId) =>
                      context.go(AppRoutes.studySession(sessionId)),
                  onOpenDeck: (deckId) =>
                      context.go(AppRoutes.studyEntry(deckId)),
                  onOpenLibrary: () => context.go(AppRoutes.decks),
                  onOpenStarterDecks: () => context.go(AppRoutes.starterDecks),
                  // Screen 27 sits under the Settings branch; Back from it
                  // lands on Settings (SB-U1).
                  onOpenSync: () => context.go(AppRoutes.settingsSync),
                  reauthNotice: accountReauthNotice(context),
                ),
              ),
            ],
          ),
          // Screen 22 (FE-A9): one page per level, under the tab bar, so
          // Back climbs one level (D5).
          StatefulShellBranch(
            observers: [LogNavigatorObserver()],
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => ProgressScreen(
                  onOpenDeck: (id) =>
                      unawaited(context.push(AppRoutes.progressDeck(id))),
                  onStartStudying: () => context.go(AppRoutes.study),
                ),
                routes: [
                  GoRoute(
                    path: AppRoutes.progressDeckChild,
                    builder: (context, state) => DeckProgressScreen(
                      deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                      onOpenDeck: (id) =>
                          unawaited(context.push(AppRoutes.progressDeck(id))),
                      onOpenAncestor: (id) => _openAncestor(
                        context,
                        id,
                        levelOf: AppRoutes.progressDeck,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [LogNavigatorObserver()],
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => SettingsScreen(
                  accountRow: accountSettingsRow(context),
                  accountBanner: accountSettingsBanner(context),
                  onOpenStudyDefaults: () =>
                      context.push(AppRoutes.settingsStudy),
                  onOpenTheme: () => context.push(AppRoutes.settingsTheme),
                  onOpenLanguage: () =>
                      context.push(AppRoutes.settingsLanguage),
                  onOpenReminder: () =>
                      context.push(AppRoutes.settingsReminder),
                  onOpenSync: () => context.push(AppRoutes.settingsSync),
                  onOpenAdmin: () => context.push(AppRoutes.settingsAdmin),
                  // The reminders feature owns the reset's consequence: the
                  // alarm follows in the same turn of the gate (DEV-218).
                  resetAppOptions: () =>
                      ProviderScope.containerOf(context)
                          .read(resetAppOptionsProvider)(),
                  onOpenGallery: hasGallery
                      ? () => context.push(AppRoutes.gallery)
                      : null,
                ),
                routes: [
                  GoRoute(
                    path: AppRoutes.settingsThemeChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const ThemeScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.settingsStudyChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const StudyDefaultsScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.settingsLanguageChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const LanguageScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.settingsReminderChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const ReminderScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.settingsSyncChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const SyncScreen(),
                  ),
                  signInRoute(rootNavigator),
                  accountRoute(rootNavigator),
                  usersRoute(rootNavigator),
                  adminRoute(rootNavigator),
                  GoRoute(
                    path: AppRoutes.settingsMonitoringChild,
                    parentNavigatorKey: rootNavigator,
                    // A deep link reaches these for anyone: the gate lets
                    // only an admin in (Codex review on PR #160).
                    builder: (context, state) => MonitoringAdminGateWidget(
                      child: MonitoringScreen(
                        pendingHeader: const SqlLogRowWidget(),
                        onOpenServerLog: (id) => unawaited(
                          context.push(AppRoutes.settingsMonitoringLog(id)),
                        ),
                        onOpenPendingLog: (id) => unawaited(
                          context.push(
                            AppRoutes.settingsMonitoringLog(id, isLocal: true),
                          ),
                        ),
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: AppRoutes.monitoringLogChild,
                        parentNavigatorKey: rootNavigator,
                        builder: (context, state) => MonitoringAdminGateWidget(
                          child: MonitoringDetailScreen(
                            logId:
                                state.pathParameters[AppRoutes
                                    .monitoringLogIdParam]!,
                            isLocal: AppRoutes.isLocalLog(
                              state.uri.queryParameters,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      welcomeRoute(),
      // Full screen, no tab bar: a session is one route, its summary too
      // (FE-A6 D2).
      GoRoute(
        path: AppRoutes.studySessionPath,
        builder: (context, state) => StudySessionScreen(
          sessionId: state.pathParameters[AppRoutes.sessionIdParam]!,
          onDone: (deckId) => context.go(AppRoutes.deck(deckId)),
          onStudyDeck: (deckId) => context.go(AppRoutes.studyEntry(deckId)),
          onLeave: (deckId) => context.go(
            deckId == null ? AppRoutes.decks : AppRoutes.deck(deckId),
          ),
        ),
      ),
      if (hasGallery)
        GoRoute(
          path: AppRoutes.gallery,
          builder: (context, state) => const GalleryScreen(),
        ),
    ],
  );
}

/// A Library level wired to the router: each deck opened is one more page,
/// so Back climbs one level (library spec §4).
DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
  void addCard(String id) => unawaited(context.push(AppRoutes.newCard(id)));
  void study(String id) => unawaited(context.push(AppRoutes.studyEntry(id)));
  final openTrash = _openTrash(context);
  return DeckLevelScreen(
    deckId: deckId,
    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
    onOpenAncestor: (id) => _openAncestor(context, id),
    onSearch: () => context.push(AppRoutes.deckSearch),
    onOpenAlgorithm: (id) =>
        unawaited(context.push(AppRoutes.deckAlgorithm(id))),
    onOpenStudy: study,
    onOpenStudyOptions: (id) =>
        unawaited(context.push(AppRoutes.studyOptions(id))),
    onAddCard: addCard,
    onImportCards: (id) => unawaited(context.push(AppRoutes.importCards(id))),
    onExportCards: (deck) => unawaited(
      showDeckExportSheet(context, deckId: deck.id, deckName: deck.name),
    ),
    // Select cards from the deck's ⋮ (DEV-307): the card feature's
    // selection, reached through the scope as the deck never imports it.
    onSelectCards: (id) =>
        ProviderScope.containerOf(context)
            .read(cardSelectionProvider(id).notifier)
            .start(),
    onOpenTrash: openTrash,
    onOpenStudyHome: () => context.go(AppRoutes.study),
    onOpenStarterDecks: _opener(context, AppRoutes.starterDecks),
    onOpenTags: _opener(context, AppRoutes.tags),
    cardAppBar: (view, back, actions) =>
        CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
    cardBreadcrumb: (id, child) =>
        CardDeckBreadcrumbWidget(deckId: id, child: child),
    cardContent: (view) => CardListSectionWidget(
      deckId: view.deck.id,
      algorithm: context.l10n.cardScheduler(view.schedulerType),
      onAddCard: () => addCard(view.deck.id),
      onOpenCard: (cardId) => unawaited(context.push(AppRoutes.card(cardId))),
      onStudy: () => study(view.deck.id),
      onOpenTrash: openTrash,
      onExport: (ids) => unawaited(
        showCardExportSheet(
          context,
          CardExportScope.selection(deckId: view.deck.id, ids: ids),
        ),
      ),
    ),
    cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () => addCard(id)),
  );
}

/// Opens the Trash on the root navigator (FE-B1 D2).
VoidCallback _openTrash(BuildContext context) =>
    _opener(context, AppRoutes.trash);

/// Pushes [location]. The router pushes it, not the page's context: a
/// toast's action can outlive its page.
VoidCallback _opener(BuildContext context, String location) {
  final router = GoRouter.of(context);
  return () => unawaited(router.push(location));
}

/// Screen 03 (FE-B4). Open goes to the new copy's root in the Library, and
/// "Create a deck" returns to the Library and opens its create dialog
/// (spec §5.1).
StarterLibraryScreen _starterDecks(
  BuildContext context,
  GlobalKey<NavigatorState> rootNavigator,
) {
  final router = GoRouter.of(context);
  return StarterLibraryScreen(
    onOpenDeck: (id) => router.go(AppRoutes.deck(id)),
    onCreateDeck: () {
      router.pop();
      final host = rootNavigator.currentState?.overlay?.context;
      if (host != null) unawaited(showCreateRootDeckDialog(host));
    },
  );
}

/// Opens the editor over the card detail. The editor closes with true when
/// it moved the card to the Trash; the detail, whose card is gone, closes
/// with it (FE-B1 D13).
Future<void> _editCard(BuildContext context, String cardId) async {
  final isTrashed = await context.push<bool>(AppRoutes.editCard(cardId));
  if (isTrashed == true && context.mounted) context.pop();
}

/// The deck path over the card editor (ruling P4a-L7, spec D8).
Widget _deckContext(String deckId, String currentLabel) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: currentLabel);

/// Ruling P2-L5: a breadcrumb tap pops the branch's stack back to [deckId],
/// or to the root for null. A deck that is not on the stack (it was opened
/// from search) is pushed over the root instead, as its [levelOf] location:
/// a Library level, or a Progress level (FE-A9 D5).
void _openAncestor(
  BuildContext context,
  String? deckId, {
  String Function(String deckId) levelOf = AppRoutes.deck,
}) {
  final router = GoRouter.of(context);
  var isOnStack = false;
  Navigator.of(context).popUntil((route) {
    final arguments = route.settings.arguments;
    isOnStack =
        deckId != null &&
        arguments is Map &&
        arguments[AppRoutes.deckIdParam] == deckId;
    return isOnStack || route.isFirst;
  });
  if (deckId == null || isOnStack) return;
  unawaited(router.push(levelOf(deckId)));
}

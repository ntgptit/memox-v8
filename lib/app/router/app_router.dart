import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/gallery/gallery_screen.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/reminders/presentation/providers/reconcile_reminder_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
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
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

/// The app's routes: four top-level branches in a stateful shell, each
/// keeping its own stack, plus the component gallery when [hasGallery]
/// (debug builds by default, so release builds never register it).
GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
  // The root navigator: a route on it covers the shell and its bottom bar.
  final rootNavigator = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigator,
    initialLocation: AppRoutes.decks,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _TabShell(navigationShell: navigationShell),
        branches: [
          // The Library (library spec §4): one page per deck level.
          StatefulShellBranch(
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
                        builder: (context, state) => _studyEntry(
                          context,
                          state.pathParameters[AppRoutes.deckIdParam]!,
                        ),
                      ),
                      // A full-screen task above the shell, as the kit
                      // draws it (FE-A3 spec §4).
                      GoRoute(
                        path: AppRoutes.studyOptionsChild,
                        parentNavigatorKey: rootNavigator,
                        builder: (context, state) => _studyOptions(
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
                ),
              ),
            ],
          ),
          // Screen 22 (FE-A9): one page per level, under the tab bar, so
          // Back climbs one level (D5).
          StatefulShellBranch(
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
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => SettingsScreen(
                  onOpenTheme: () => context.push(AppRoutes.settingsTheme),
                  onOpenLanguage: () =>
                      context.push(AppRoutes.settingsLanguage),
                  onOpenReminder: () =>
                      context.push(AppRoutes.settingsReminder),
                  // The reset turned the reminder off; the pending alarm
                  // follows through the gate (FE-B5 spec D7).
                  onAppOptionsReset: () => unawaited(
                    _reconcileAfterReset(ProviderScope.containerOf(context)),
                  ),
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
                    path: AppRoutes.settingsLanguageChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const LanguageScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.settingsReminderChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const ReminderScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
    onOpenTrash: openTrash,
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

/// Screen 14 with the deck's name and path from the deck feature, which
/// the study feature may not read (FE-A6 D16).
StudyEntryScreen _studyEntry(BuildContext context, String deckId) =>
    StudyEntryScreen(
      deckId: deckId,
      title: DeckStudyHeaderWidget(
        deckId: deckId,
        part: DeckStudyHeaderPart.title,
      ),
      breadcrumb: DeckStudyHeaderWidget(
        deckId: deckId,
        part: DeckStudyHeaderPart.breadcrumb,
      ),
      onOpenSession: (sessionId) =>
          context.go(AppRoutes.studySession(sessionId)),
      onOpenStudyOptions: () =>
          unawaited(context.push(AppRoutes.studyOptions(deckId))),
    );

/// Screen 15 with the deck's path from the deck feature, which settings
/// may not read (FE-A3 plan 2, C6).
StudyOptionsScreen _studyOptions(BuildContext context, String deckId) =>
    StudyOptionsScreen(
      deckId: deckId,
      breadcrumb: DeckStudyHeaderWidget(
        deckId: deckId,
        part: DeckStudyHeaderPart.breadcrumb,
        trailingLabel: context.l10n.deckStudyOptions,
      ),
    );

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

/// The bottom nav around the current branch.
class _TabShell extends StatelessWidget {
  const _TabShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      body: navigationShell,
      bottomBar: MxBottomNav(
        destinations: [
          MxNavDestination(
            icon: AppIcons.library,
            selectedIcon: AppIcons.librarySelected,
            label: l10n.navLibrary,
          ),
          MxNavDestination(
            icon: AppIcons.study,
            selectedIcon: AppIcons.studySelected,
            label: l10n.navStudy,
          ),
          MxNavDestination(
            icon: AppIcons.progress,
            selectedIcon: AppIcons.progressSelected,
            label: l10n.navProgress,
          ),
          MxNavDestination(
            icon: AppIcons.settings,
            selectedIcon: AppIcons.settingsSelected,
            label: l10n.navSettings,
          ),
        ],
        selectedIndex: navigationShell.currentIndex,
        // Re-tapping the current tab returns its branch to its root.
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Reconcile after Reset app options. A refusal or a read that fails
/// changes nothing on screen; the next start or resume reconciles again, as
/// `app.dart` does.
Future<void> _reconcileAfterReset(ProviderContainer container) async {
  try {
    await container.read(reconcileReminderProvider)();
  } on Failure {
    // Retried at the next start or resume.
  }
}

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/placeholder/placeholder_shell.dart';
import 'package:memox/app/placeholder/rebuild_placeholder.dart';
import 'package:memox/app/placeholder/welcome_placeholder.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/app/router/log_navigator_observer.dart';

/// SP2 (spec 2026-10-04-sp2 §5.2): every route of
/// docs/screens/SCREEN_CATALOG.md stays registered and shows a placeholder
/// naming its screen, so deep links, the reminder tap and the account
/// redirect keep their contract until SP3 rebuilds each screen. The four
/// tabs follow docs/NAVIGATION.md; a route that covers the shell there sits
/// on the root navigator here too.
GoRouter buildAppRouter({
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
  final rootNavigator = GlobalKey<NavigatorState>();
  GoRoute page(
    String path,
    String scrId, {
    bool isOverShell = false,
    List<RouteBase> routes = const [],
  }) => GoRoute(
    path: path,
    parentNavigatorKey: isOverShell ? rootNavigator : null,
    builder: (context, state) => RebuildPlaceholder(scrId: scrId),
    routes: routes,
  );
  StatefulShellBranch branch(GoRoute root) =>
      StatefulShellBranch(observers: [LogNavigatorObserver()], routes: [root]);
  return GoRouter(
    navigatorKey: rootNavigator,
    observers: [LogNavigatorObserver()],
    initialLocation: AppRoutes.decks,
    refreshListenable: refreshListenable,
    redirect: redirect,
    errorBuilder: (context, state) => const UnknownRoutePlaceholder(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            PlaceholderShell(navigationShell: navigationShell),
        branches: [
          branch(
            page(
              AppRoutes.decks,
              'SCR-DECK-001',
              routes: [
                page(
                  AppRoutes.deckChild,
                  'SCR-DECK-001 · SCR-CARD-001',
                  routes: [
                    page(AppRoutes.cardNewChild, 'SCR-CARD-002'),
                    page(
                      AppRoutes.cardImportChild,
                      'SCR-TRANSFER-001',
                      isOverShell: true,
                    ),
                    page(AppRoutes.studyChild, 'SCR-STUDY-002'),
                    page(
                      AppRoutes.studyOptionsChild,
                      'SCR-SETTINGS-001',
                      isOverShell: true,
                    ),
                    page(AppRoutes.algorithmChild, 'SCR-SRS-001'),
                  ],
                ),
                page(AppRoutes.trashChild, 'SCR-TRASH-001', isOverShell: true),
                page(
                  AppRoutes.starterDecksChild,
                  'SCR-STARTER-001',
                  isOverShell: true,
                ),
                page(AppRoutes.tagsChild, 'SCR-TAG-001', isOverShell: true),
                page(AppRoutes.searchChild, 'SCR-SEARCH-001'),
                page(
                  AppRoutes.cardChild,
                  'SCR-CARD-004',
                  routes: [page(AppRoutes.cardEditChild, 'SCR-CARD-003')],
                ),
              ],
            ),
          ),
          branch(page(AppRoutes.study, 'SCR-STUDY-001')),
          branch(
            page(
              AppRoutes.progress,
              'SCR-PROGRESS-001',
              routes: [page(AppRoutes.progressDeckChild, 'SCR-PROGRESS-001')],
            ),
          ),
          branch(
            page(
              AppRoutes.settings,
              'SCR-SETTINGS-002',
              routes: [
                page(
                  AppRoutes.settingsThemeChild,
                  'SCR-SETTINGS-003',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsLanguageChild,
                  'SCR-SETTINGS-004',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsReminderChild,
                  'SCR-REMINDER-001',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsSyncChild,
                  'SCR-ACCOUNT-001',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsSignInChild,
                  'SCR-ACCOUNT-003',
                  isOverShell: true,
                  routes: [
                    page(
                      AppRoutes.settingsSignInCodeChild,
                      'SCR-ACCOUNT-004',
                      isOverShell: true,
                    ),
                  ],
                ),
                page(
                  AppRoutes.settingsAccountChild,
                  'SCR-ACCOUNT-005',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsUsersChild,
                  'SCR-ACCOUNT-006',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsMonitoringChild,
                  'SCR-MONITORING-001',
                  isOverShell: true,
                  routes: [
                    page(
                      AppRoutes.monitoringLogChild,
                      'SCR-MONITORING-001',
                      isOverShell: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomePlaceholder(
          from: AppRoutes.inAppOr(
            state.uri.queryParameters[AppRoutes.welcomeFromParam],
            AppRoutes.decks,
          ),
        ),
      ),
      page(AppRoutes.studySessionPath, 'SCR-STUDY-003…SCR-STUDY-009'),
    ],
  );
}

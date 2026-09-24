import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/gallery/gallery_screen.dart';
import 'package:memox/app/placeholder_screen.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

/// The app's routes: four top-level branches in a stateful shell, each
/// keeping its own stack, plus the component gallery when [hasGallery]
/// (debug builds by default, so release builds never register it).
GoRouter buildAppRouter({bool hasGallery = kDebugMode}) => GoRouter(
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
                ),
                GoRoute(
                  path: AppRoutes.searchChild,
                  builder: (context, state) => DeckSearchScreen(
                    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
                  ),
                ),
              ],
            ),
          ],
        ),
        _branch(AppRoutes.study, (context) => context.l10n.navStudy),
        _branch(AppRoutes.progress, (context) => context.l10n.navProgress),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => PlaceholderScreen(
                title: context.l10n.navSettings,
                onOpenGallery: hasGallery
                    ? () => context.push(AppRoutes.gallery)
                    : null,
              ),
            ),
          ],
        ),
      ],
    ),
    if (hasGallery)
      GoRoute(
        path: AppRoutes.gallery,
        builder: (context, state) => const GalleryScreen(),
      ),
  ],
);

/// A Library level wired to the router: each deck opened is one more page,
/// so Back climbs one level (library spec §4).
DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) =>
    DeckLevelScreen(
      deckId: deckId,
      onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
      onOpenAncestor: (id) => _openAncestor(context, id),
      onSearch: () => context.push(AppRoutes.deckSearch),
    );

/// Ruling P2-L5: a breadcrumb tap pops the Library stack back to [deckId],
/// or to the root for null. A deck that is not on the stack (it was opened
/// from search) is pushed over the root instead.
void _openAncestor(BuildContext context, String? deckId) {
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
  unawaited(router.push(AppRoutes.deck(deckId)));
}

StatefulShellBranch _branch(String path, String Function(BuildContext) title) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) => PlaceholderScreen(title: title(context)),
        ),
      ],
    );

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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/gallery/gallery_screen.dart';
import 'package:memox/app/placeholder_screen.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
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
        _branch(AppRoutes.decks, (context) => context.l10n.navLibrary),
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

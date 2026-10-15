import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_nav_rail.dart';

/// The top-level destinations around the current branch: a bottom nav on a
/// phone, a rail from [context.dimens.breakpointMedium] (FE-C5). A window short
/// of [context.dimens.breakpointCompactHeight] keeps the bar at any width, as
/// Material 3 asks for a bar when the width or the height is compact. Beside
/// the rail the branch gets its own width and loses the inset the rail took, so
/// what it lays out and centres (the column, sheets, snackbars) is measured
/// against its own area; its window size class and screen margin still follow
/// the whole window ([WindowWidthScope]).
class AppTabShell extends StatelessWidget {
  const AppTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context.l10n);
    final selectedIndex = navigationShell.currentIndex;
    final media = MediaQuery.of(context);
    final isShort = media.size.height < context.dimens.breakpointCompactHeight;
    if (context.windowSize == WindowSize.compact || isShort) {
      return MxAppShell(
        body: navigationShell,
        bottomBar: MxBottomNav(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onSelected: _onSelected,
        ),
      );
    }
    return ColoredBox(
      color: context.colors.surface,
      child: Row(
        // The rail runs the full height, its destinations from the top.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxNavRail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: _onSelected,
          ),
          Expanded(
            child: MediaQuery(
              data: _besideRail(
                media,
                Directionality.of(context),
                context.dimens.sizeRail,
              ),
              child: WindowWidthScope(
                width: media.size.width,
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Re-tapping the current tab returns its branch to its root.
  void _onSelected(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  /// The window less the rail and the start inset the rail took.
  static MediaQueryData _besideRail(
    MediaQueryData media,
    TextDirection direction,
    double railWidth,
  ) {
    final isLtr = direction == TextDirection.ltr;
    final startInset = isLtr ? media.padding.left : media.padding.right;
    EdgeInsets withoutStart(EdgeInsets insets) =>
        isLtr ? insets.copyWith(left: 0) : insets.copyWith(right: 0);
    return media.copyWith(
      size: Size(media.size.width - railWidth - startInset, media.size.height),
      padding: withoutStart(media.padding),
      viewPadding: withoutStart(media.viewPadding),
    );
  }

  static List<MxNavDestination> _destinations(AppLocalizations l10n) => [
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
  ];
}

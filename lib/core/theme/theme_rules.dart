import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The Material 3 window size classes the layout follows.
enum WindowSize { compact, medium, expanded }

/// Publishes the width of the whole window below a shell that narrows its
/// children's MediaQuery (the tab shell hands the area beside the rail to the
/// branch). `windowSize` and `screenMargin` read it, so the size class belongs
/// to the window and not to the pane a screen happens to sit in.
class WindowWidthScope extends InheritedWidget {
  const WindowWidthScope({
    super.key,
    required this.width,
    required super.child,
  });

  final double width;

  /// The scope's width, or the MediaQuery width outside any scope.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WindowWidthScope>()?.width ??
      MediaQuery.sizeOf(context).width;

  @override
  bool updateShouldNotify(WindowWidthScope oldWidget) =>
      width != oldWidget.width;
}

/// Design System rules of the form "this mode uses role A, that mode role B".
/// The only widget-facing place that branches on the theme's brightness to
/// pick a colour; a widget never does.
extension ThemeRules on BuildContext {
  /// Icons and text in the accent colour. `primary` on the dark page reaches
  /// only 3.01:1, so dark uses the lighter fixed step (DS README, Primary).
  Color get accentColor => switch (Theme.of(this).brightness) {
    Brightness.light => colors.primary,
    Brightness.dark => colors.primaryFixedDim,
  };

  /// The glyph on a fill in the accent colour (the check in a checked box):
  /// `onPrimary` on light `primary`, `onPrimaryFixed` on dark `primaryFixedDim`.
  Color get onAccentColor => switch (Theme.of(this).brightness) {
    Brightness.light => colors.onPrimary,
    Brightness.dark => colors.onPrimaryFixed,
  };

  /// The deck icon on its tile surface: `info` on the light tile, the lighter
  /// `infoContainer` on the dark one (DS README, Colour).
  Color get deckIconColor => switch (Theme.of(this).brightness) {
    Brightness.light => mxColors.info,
    Brightness.dark => mxColors.infoContainer,
  };

  /// The window's size class, by `breakpointMedium` / `breakpointExpanded`.
  /// It follows the whole window's width, also inside a shell that gives a
  /// screen only the area beside a rail ([WindowWidthScope]).
  WindowSize get windowSize {
    final width = WindowWidthScope.of(this);
    if (width >= dimens.breakpointExpanded) return WindowSize.expanded;
    if (width >= dimens.breakpointMedium) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// Left and right screen margin: `marginScreen` on compact windows,
  /// `marginScreenMedium` from 600.
  double get screenMargin => switch (windowSize) {
    WindowSize.compact => dimens.marginScreen,
    WindowSize.medium || WindowSize.expanded => dimens.marginScreenMedium,
  };
}

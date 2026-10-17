import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The window size classes the layout follows: compact, medium, expanded.
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

/// The layout rules every screen follows: the window's size class and the
/// screen margin it sets.
extension ThemeRules on BuildContext {
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

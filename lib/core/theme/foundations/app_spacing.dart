import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_size.dart';

/// The spacing rhythm ("Flashcard Color Tokens" §4.1): gap, padding and
/// inset only. Component size is AppSize's, not this scale's.
abstract final class AppSpacing {
  /// Icon-to-label, inside a chip.
  static const double micro = 4;

  /// Button padding, tight stacks.
  static const double control = 8;

  /// Related rows inside one block.
  static const double grouped = 12;

  /// The screen's side margin on a compact window (`margin-screen`), and the
  /// gap between list items. A screen's side margin reads
  /// [ScreenMargin.screenMargin], which steps up to [gutterMedium].
  static const double gutter = 16;

  /// The screen's side margin from [AppSize.navRailBreakpoint]
  /// (`margin-screen-medium`).
  static const double gutterMedium = 24;

  /// Card and sheet interior.
  static const double card = 24;

  /// A card's interior on the overview screen (Today).
  static const double cardCompact = 16;

  /// Between sections of a screen.
  static const double section = 24;

  /// Between major visual groups.
  static const double major = 32;

  /// Scroll tail above pinned chrome, so the last item is never trapped.
  static const double pageEnd = 48;
}

/// The window's width, for a subtree whose MediaQuery an ancestor narrowed
/// to its own area: the tab shell beside its rail (FE-C5). The window size
/// class ("Flashcard Color Tokens" §5) is the window's, not the area's.
class WindowWidthScope extends InheritedWidget {
  const WindowWidthScope({
    super.key,
    required this.width,
    required super.child,
  });

  final double width;

  /// The nearest scope's width, or the MediaQuery's where there is none.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WindowWidthScope>()?.width ??
      MediaQuery.sizeOf(context).width;

  @override
  bool updateShouldNotify(WindowWidthScope oldWidget) =>
      width != oldWidget.width;
}

/// The window size class and the screen's side margin it sets (§4.1, §5).
extension ScreenMargin on BuildContext {
  /// Whether the window is compact: narrower than
  /// [AppSize.navRailBreakpoint].
  bool get isCompactWindow =>
      WindowWidthScope.of(this) < AppSize.navRailBreakpoint;

  /// [AppSpacing.gutter] on a compact window, [AppSpacing.gutterMedium] from
  /// [AppSize.navRailBreakpoint].
  double get screenMargin =>
      isCompactWindow ? AppSpacing.gutter : AppSpacing.gutterMedium;
}

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

/// The screen's side margin for the window in scope (§4.1, §5).
extension ScreenMargin on BuildContext {
  /// [AppSpacing.gutter] below [AppSize.navRailBreakpoint],
  /// [AppSpacing.gutterMedium] from it.
  double get screenMargin =>
      MediaQuery.sizeOf(this).width < AppSize.navRailBreakpoint
      ? AppSpacing.gutter
      : AppSpacing.gutterMedium;
}

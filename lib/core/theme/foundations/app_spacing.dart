/// V3 spacing rhythm: gap, padding and inset only. Component size is
/// AppSize's, not this scale's.
abstract final class AppSpacing {
  /// Icon-to-label, inside a chip.
  static const double micro = 4;

  /// Button padding, tight stacks.
  static const double control = 8;

  /// Related rows inside one block.
  static const double grouped = 12;

  /// Horizontal screen padding and the gap between list items.
  static const double gutter = 16;

  /// Card and sheet interior.
  static const double card = 20;

  /// Between sections of a screen.
  static const double section = 24;

  /// Between major visual groups.
  static const double major = 32;

  /// Scroll tail above pinned chrome, so the last item is never trapped.
  static const double pageEnd = 48;
}

/// V3 component geometry. Heights around text are minimums: a wrapped label
/// or OS text scaling grows the box. The painted size and the touch area are
/// separate; [touchTarget] is the minimum interactive region for everything.
abstract final class AppSize {
  static const double buttonRegular = 48;
  static const double buttonSmall = 36;
  static const double buttonCompact = 32;

  /// Chip and filter chip. Fixed: a chip never wraps, its row scrolls.
  static const double chip = 28;

  /// Text field and search field.
  static const double input = 52;

  /// The painted circle of an icon button only; the hit area is [touchTarget].
  static const double iconButtonInk = 36;

  static const double touchTarget = 48;

  /// A list row grows to two title lines from here.
  static const double listRowMin = 48;

  static const double appBar = 56;

  /// The bottom-nav block; the bar itself is drawn at [bottomNavBar].
  static const double bottomNavBlock = 80;
  static const double bottomNavBar = 64;

  /// Square, icon only. V3 has no extended FAB.
  static const double fab = 52;
}

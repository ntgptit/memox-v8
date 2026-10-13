/// Component geometry ("Flashcard Color Tokens" §4.3). Heights around text
/// are minimums: a wrapped label or OS text scaling grows the box. The
/// painted size and the touch area are separate; [touchTarget] is the
/// minimum interactive region for everything, a 32 or 40 button included.
abstract final class AppSize {
  /// The default button (M3 Expressive S): one standing alone, the study
  /// action bar, a button the width of its card.
  static const double buttonRegular = 40;

  /// The small button (M3 Expressive XS): one in a row with other content.
  static const double buttonSmall = 32;

  /// The compact geometry: the small button's height (the system has two
  /// button sizes).
  static const double buttonCompact = 32;

  /// Chip and filter chip. Fixed: a chip never wraps, its row scrolls.
  static const double chip = 28;

  /// A text field.
  static const double input = 52;

  /// MxSearchField.
  static const double search = 56;

  /// The painted circle of an icon button only; the hit area is [touchTarget].
  static const double iconButtonInk = 36;

  static const double touchTarget = 48;

  /// A code field's slot (sign-in redesign 2026-10-05): a minimum, so the
  /// digit grows with the text scale.
  static const double codeSlot = 56;

  /// A list row grows to two title lines from here.
  static const double listRowMin = 48;

  /// The title bar: a 48 control and 8 above and below it.
  static const double appBar = 64;

  /// MxBottomNav's whole height (M3 Expressive), before the system inset.
  static const double bottomNavBar = 64;

  /// The bottom navigation block: the bar itself, nothing around it.
  static const double bottomNavBlock = 64;

  /// The pill behind the selected destination's glyph.
  static const double navIndicatorWidth = 56;
  static const double navIndicatorHeight = 32;

  /// Square, icon only. V3 has no extended FAB.
  static const double fab = 52;

  /// From this window width (`breakpoint-medium`) the top-level destinations
  /// sit in a rail and the side margin is AppSpacing.gutterMedium.
  static const double navRailBreakpoint = 600;

  /// From this window width (`breakpoint-expanded`) medium becomes expanded.
  static const double expandedBreakpoint = 840;

  /// The navigation rail's width.
  static const double navRail = 80;

  /// The one-column width: a compact window's column and every study
  /// session, at every window size.
  static const double contentMaxWidth = 599;

  /// The content area from [navRailBreakpoint], centred (the overview's two
  /// columns).
  static const double contentMaxWidthWide = 1040;

  /// The narrowest column of the overview's two (Study home): it splits in
  /// two once its content area holds two of these and the section gap
  /// ("Flashcard Color Tokens" §5: 672 with the 24 margins).
  static const double overviewColumnMin = 300;

  /// A linear progress track's height.
  static const double progressTrack = 4;

  /// A deck's icon tile in a list (DeckTile).
  static const double deckTile = 64;

  /// A profile avatar.
  static const double avatar = 48;

  /// A node on a timeline's rail: the card history's answers and markers
  /// (DEV-170).
  static const double timelineDot = 14;
}

/// V3 icon sizes. Nothing goes below [inline]. The visual size never sets the
/// touch area; see AppSize.touchTarget.
abstract final class AppIconSize {
  /// Inside body text, compact utility.
  static const double inline = 16;

  /// A brand's mark on a button, such as Google's G (account UI spec U6):
  /// the size its guidelines set beside a label.
  static const double brandMark = 18;

  /// Dense rows, metadata, nav glyphs, FAB glyph.
  static const double compact = 20;

  /// App-bar and navigation actions.
  static const double standard = 24;

  /// Feature tiles.
  static const double large = 32;

  /// Empty states, hero marks.
  static const double illustrative = 40;
}

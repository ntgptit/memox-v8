/// V3 icon sizes. Nothing goes below [inline]. The visual size never sets the
/// touch area; see AppSize.touchTarget.
abstract final class AppIconSize {
  /// Inside body text, compact utility.
  static const double inline = 16;

  /// Dense rows, metadata, nav glyphs, FAB glyph.
  static const double compact = 20;

  /// App-bar and navigation actions.
  static const double standard = 24;

  /// Feature tiles.
  static const double large = 32;

  /// Empty states, hero marks.
  static const double illustrative = 40;
}

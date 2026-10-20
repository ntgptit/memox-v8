import 'package:flutter/foundation.dart' show immutable;
import 'package:material_ui/material_ui.dart' show ThemeExtension;

/// The app's own geometry, read as `context.dimens` (ADR-026): the spacing
/// scale, screen margins, layout breakpoints and the few sizes a shared
/// widget lays out by. Component geometry (button, field, chip and control
/// sizes, radii, borders, focus rings, state layers) is ForUI's and is read
/// from the ForUI theme, never duplicated here.
///
/// It rides on `FThemeData.extensions`. Nothing in it changes between light
/// and dark, so it does not interpolate.
@immutable
class AppDimens extends ThemeExtension<AppDimens> {
  const AppDimens();

  // The 4-step spacing scale.
  double get space4 => 4;
  double get space8 => 8;
  double get space12 => 12;
  double get space16 => 16;
  double get space24 => 24;
  double get space32 => 32;
  double get space48 => 48;

  /// A row's title to its subtitle or metadata line, tighter than the
  /// scale's steps: the two lines read as one item (spacing spec
  /// 2026-10-20, owner).
  double get spaceRowLine => 2;

  /// Left and right screen margin on a compact window.
  double get marginScreen => 16;

  /// Left and right screen margin from `breakpointMedium` on.
  double get marginScreenMedium => 24;

  /// The minimum touch target, 48 × 48 (Android accessibility guideline).
  double get sizeControl => 48;

  /// An icon inside body text; the smallest icon.
  double get sizeIconInline => 16;

  /// Dense rows, metadata and navigation glyphs.
  double get sizeIconCompact => 20;

  /// The standard icon.
  double get sizeIcon => 24;

  /// The glyph of a large tile, such as an empty state's.
  double get sizeIconTile => 32;

  /// A thin progress track.
  double get sizeTrack => 4;

  /// The bottom navigation bar's minimum height.
  double get sizeNav => 64;

  /// The navigation rail's width.
  double get sizeRail => 80;

  /// The app bar's minimum height.
  double get sizeAppBar => 64;

  /// The floating action button, square.
  double get sizeFab => 56;

  /// Minimum height of a one-line list row.
  double get sizeListRow => 56;

  /// Minimum height of a list row with a supporting line.
  double get sizeListRowTwoLine => 72;

  /// The content column on a compact window, and a study session everywhere.
  double get sizeContentMax => 599;

  /// The content column from `breakpointMedium` on.
  double get sizeContentMaxWide => 1040;

  /// Window width from which the window is medium.
  double get breakpointMedium => 600;

  /// Window width from which the window is expanded.
  double get breakpointExpanded => 840;

  /// Window height below which navigation stays a bottom bar.
  double get breakpointCompactHeight => 480;

  /// A line that carries meaning, twice the hairline: a selected edge, a
  /// timeline rail, a step connector.
  double get strokeEmphasis => 2;

  /// Readable content that steps back: an answered choice out of play.
  double get opacityMuted => 0.7;

  @override
  AppDimens copyWith() => this;

  @override
  AppDimens lerp(ThemeExtension<AppDimens>? other, double t) => this;
}

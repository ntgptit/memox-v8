import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';

/// The app's [FTypography]: ForUI's touch type scale set in Be Vietnam Pro,
/// with Noto Sans KR as the Korean fallback (both bundled, OFL; ADR-025).
///
/// The sizes are ForUI's touch sizes. The line heights are not: ForUI sets
/// 12 and 14 at 1.0 and 1.25, which clips stacked Vietnamese diacritics
/// (Ẳ, Ổ, Ỗ) in a one-line label cut with an ellipsis, so every size used
/// for text keeps at least 1.4, and the small ones 1.5.
abstract final class AppTypography {
  /// The family for code and other fixed-pitch text.
  static const String monoFamily = 'monospace';

  static const String _family = 'BeVietnamPro';
  static const List<String> _fallback = ['NotoSansKR'];

  /// The type scale inked in [colors]' foreground, as ForUI's touch scale is.
  static FTypography build(FColors colors) {
    TextStyle size(double fontSize, double height) => TextStyle(
      color: colors.foreground,
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: fontSize,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final typeface = FTypeface(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      xs3: size(10, 1.6),
      xs2: size(12, 1.5),
      xs: size(14, 1.5),
      sm: size(16, 1.5),
      md: size(18, 1.5),
      lg: size(20, 1.4),
      xl: size(22, 1.4),
      xl2: size(30, 1.3),
      xl3: size(36, 1.25),
      xl4: size(48, 1.15),
      xl5: size(60, 1.1),
      xl6: size(72, 1.1),
      xl7: size(96, 1.05),
      xl8: size(108, 1.05),
    );
    return FTypography(display: typeface, body: typeface);
  }
}

/// The text roles the app's widgets read, as `context.texts.<role>`, each a
/// step of the ForUI scale at a weight. It holds no value of its own: a size
/// comes from [FTypography], so a scale change reaches every role.
///
/// A widget uses a role as it is and changes only its colour. Weights stop at
/// 600, the heaviest Be Vietnam Pro the app bundles.
extension type const MxTextRoles(FTypography _scale) {
  /// A large figure: a stat's value (30, 600).
  TextStyle get figure => _weighted(_scale.display.xl2, FontWeight.w600);

  /// The term on a study face, a sign-in code's digits (22, 500).
  TextStyle get term => _weighted(_scale.display.xl, FontWeight.w500);

  /// The term on a compact tile (20, 400).
  TextStyle get termCompact => _weighted(_scale.display.lg, FontWeight.w400);

  /// A screen's title in its app bar (20, 600).
  TextStyle get screenTitle => _weighted(_scale.display.lg, FontWeight.w600);

  /// The title of a section or a card (18, 600).
  TextStyle get sectionTitle => _weighted(_scale.body.md, FontWeight.w600);

  /// The title of a row, a setting or a sheet (16, 500).
  TextStyle get itemTitle => _weighted(_scale.body.sm, FontWeight.w500);

  /// Reading text: a field's value, a card's content (16, 400).
  TextStyle get content => _weighted(_scale.body.sm, FontWeight.w400);

  /// Supporting text: a subtitle, a dialog body, a note (14, 400).
  TextStyle get body => _weighted(_scale.body.xs, FontWeight.w400);

  /// A field's supporting line or error (12, 400).
  TextStyle get caption => _weighted(_scale.body.xs2, FontWeight.w400);

  /// A button's label (16, 500).
  TextStyle get button => _weighted(_scale.body.sm, FontWeight.w500);

  /// A label: a field's name, a metadata line, a banner message (14, 500).
  TextStyle get label => _weighted(_scale.body.xs, FontWeight.w500);

  /// Small metadata: an overline, a badge, a counter (12, 500).
  TextStyle get meta => _weighted(_scale.body.xs2, FontWeight.w500);
}

/// [style] at [weight], with a variable font's `wght` axis moved too: on a
/// variable font (Noto Sans KR) fontWeight alone paints the default instance;
/// on a static one the variation is harmless.
TextStyle _weighted(TextStyle style, FontWeight weight) => style.copyWith(
  fontWeight: weight,
  fontVariations: [FontVariation.weight(weight.value.toDouble())],
);

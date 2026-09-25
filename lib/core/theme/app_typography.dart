import 'package:flutter/material.dart';

/// The V3 type scale bound to Material's TextTheme (01-foundations.md).
///
/// Seven roles, one family. A component's own treatment (the button label, the
/// app-bar title) overrides the nearest role in that component; it never adds a
/// global style here.
abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  static const double _tightTracking = -0.64;

  /// Re-weights [style] and moves the variable font's `wght` axis with it.
  /// On a variable font, fontWeight alone reports one weight and paints the
  /// font's default instance.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation.weight(weight.value.toDouble())],
      );

  /// [base] with the seven V3 roles merged over it and every slot's `wght`
  /// axis synced to its weight, so the slots V3 does not define still render
  /// at the weight they declare.
  static TextTheme bind(TextTheme base) {
    final merged = base.merge(_roles).apply(fontFamily: fontFamily);
    return merged.copyWith(
      displayLarge: _synced(merged.displayLarge),
      displayMedium: _synced(merged.displayMedium),
      displaySmall: _synced(merged.displaySmall),
      headlineLarge: _synced(merged.headlineLarge),
      headlineMedium: _synced(merged.headlineMedium),
      headlineSmall: _synced(merged.headlineSmall),
      titleLarge: _synced(merged.titleLarge),
      titleMedium: _synced(merged.titleMedium),
      titleSmall: _synced(merged.titleSmall),
      bodyLarge: _synced(merged.bodyLarge),
      bodyMedium: _synced(merged.bodyMedium),
      bodySmall: _synced(merged.bodySmall),
      labelLarge: _synced(merged.labelLarge),
      labelMedium: _synced(merged.labelMedium),
      labelSmall: _synced(merged.labelSmall),
    );
  }

  static final TextTheme _roles = TextTheme(
    // stat: large metric, tabular numerals.
    displayMedium: _role(
      size: 40,
      weight: FontWeight.w600,
      height: 1.0,
      tracking: _tightTracking,
      isTabular: true,
    ),
    // display: hero figure.
    displaySmall: _role(
      size: 32,
      weight: FontWeight.w800,
      height: 1.1,
      tracking: _tightTracking,
    ),
    // headline: screen headline.
    headlineSmall: _role(
      size: 24,
      weight: FontWeight.w700,
      height: 1.2,
      tracking: _tightTracking,
    ),
    // title: section and screen titles.
    titleLarge: _role(
      size: 20,
      weight: FontWeight.w700,
      height: 1.2,
      tracking: _tightTracking,
    ),
    // body large: list titles, emphasised body.
    bodyLarge: _role(size: 16, weight: FontWeight.w500, height: 1.5),
    // body: default running text.
    bodyMedium: _role(size: 14, weight: FontWeight.w400, height: 1.5),
    // caption: metadata, counts, chips. 12 is a hard floor. Tracking belongs
    // to the roles that want it (overline 0.6, field count 0.2, the study
    // mode badge 1.2): the kit's 12px sentences carry none.
    labelSmall: _role(size: 12, weight: FontWeight.w600, height: 1.4),
  );

  static TextStyle _role({
    required double size,
    required FontWeight weight,
    required double height,
    double tracking = 0,
    bool isTabular = false,
  }) => withWeight(
    TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: height,
      letterSpacing: tracking,
      fontFeatures: isTabular ? const [FontFeature.tabularFigures()] : null,
    ),
    weight,
  );

  static TextStyle? _synced(TextStyle? style) {
    if (style == null) return null;
    return withWeight(style, style.fontWeight ?? FontWeight.w400);
  }
}

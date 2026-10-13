import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/text_theme.g.dart';

/// The Design System type scale bound to Material's [TextTheme].
///
/// Widgets use the role directly, `context.texts.titleSmall`, and change only
/// its colour (or, for code, its family). Size, weight, tracking and height are
/// the token's; nothing restyles them in the UI.
///
/// A single-line label that is cut with an ellipsis needs a line height of at
/// least 1.5, otherwise stacked Vietnamese diacritics (Ẳ, Ổ, Ỗ) are clipped.
/// The line height stays what `design/tokens.json` says; a screen that clips
/// is a finding to report, not a reason to raise the height.
abstract final class AppTypography {
  /// The family for code and other fixed-pitch text.
  static const String monoFamily = 'monospace';

  /// Re-weights [style] and moves a variable font's `wght` axis with it.
  /// On a variable font, fontWeight alone reports one weight and paints the
  /// font's default instance; on a static font the variation is harmless.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation.weight(weight.value.toDouble())],
      );

  /// [base] with the twelve Design System roles merged over it, the family and
  /// its Korean fallback applied, and every slot's `wght` axis synced to its
  /// weight so the Material slots the Design System leaves out still render at
  /// the weight they declare.
  static TextTheme bind(TextTheme base) {
    final merged = base
        .merge(generatedTextTheme)
        .apply(
          fontFamily: kFontFamily,
          fontFamilyFallback: kFontFamilyFallback,
        );
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

  static TextStyle? _synced(TextStyle? style) {
    if (style == null) return null;
    return withWeight(style, style.fontWeight ?? FontWeight.w400);
  }
}

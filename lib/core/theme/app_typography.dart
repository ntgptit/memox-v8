import 'package:flutter/material.dart';

/// The type scale bound to Material's TextTheme ("Flashcard Color Tokens"
/// §3, ADR-022).
///
/// Twelve roles, one family (Be Vietnam Pro) with Noto Sans KR behind it for
/// Korean. `height` is the role's line height over its size. Interface text
/// is 14; the study content (a term, a meaning) keeps its own size and no
/// tracking. Only titleLarge is bold (600); titles, item names and
/// navigation labels are 500; everything else, a button's label included,
/// is 400. Nothing is below 12.
abstract final class AppTypography {
  static const String fontFamily = 'BeVietnamPro';

  /// The Korean face, reached when Be Vietnam Pro has no glyph.
  static const List<String> fontFamilyFallback = ['NotoSansKR'];

  /// Re-weights [style] and moves a variable font's `wght` axis with it (the
  /// Noto Sans KR fallback is variable); a static face ignores the axis.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation.weight(weight.value.toDouble())],
      );

  /// [base] with the twelve roles merged over it, every slot in the family
  /// and its fallback, and every slot's `wght` axis synced to its weight, so
  /// the slots the scale does not define keep Material's size in the family.
  static TextTheme bind(TextTheme base) {
    final merged = base
        .merge(_roles)
        .apply(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback);
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
    // display-term: the word being studied on a flashcard.
    displaySmall: _role(size: 24, line: 32, weight: FontWeight.w400),
    // term-tile: the Korean word in a match tile.
    headlineSmall: _role(size: 20, line: 28, weight: FontWeight.w400),
    // display-stat: a key number that replaces a sentence; tabular.
    displayMedium: _role(
      size: 28,
      line: 36,
      weight: FontWeight.w500,
      isTabular: true,
    ),
    // title-section: a section heading.
    titleLarge: _role(size: 20, line: 28, weight: FontWeight.w600),
    // title-card: a card's title, a compact stat's number.
    titleMedium: _role(
      size: 18,
      line: 24,
      weight: FontWeight.w500,
      tracking: 0.15,
    ),
    // title-item: an item or row title.
    titleSmall: _role(
      size: 14,
      line: 20,
      weight: FontWeight.w500,
      tracking: 0.1,
    ),
    // body-content: the card content the learner reads.
    bodyLarge: _role(size: 16, line: 24, weight: FontWeight.w400),
    // body: interface copy.
    bodyMedium: _role(
      size: 14,
      line: 20,
      weight: FontWeight.w400,
      tracking: 0.25,
    ),
    // body-tile: a meaning in a match tile or a guess option.
    bodySmall: _role(size: 13, line: 16, weight: FontWeight.w400),
    // label-button: a button's label at both sizes.
    labelLarge: _role(
      size: 14,
      line: 20,
      weight: FontWeight.w400,
      tracking: 0.1,
    ),
    // label-meta: progress text, a placeholder, a banner, a count.
    labelMedium: _role(
      size: 14,
      line: 20,
      weight: FontWeight.w400,
      tracking: 0.5,
    ),
    // label-nav: a navigation label; the 12 floor.
    labelSmall: _role(
      size: 12,
      line: 16,
      weight: FontWeight.w500,
      tracking: 0.5,
    ),
  );

  static TextStyle _role({
    required double size,
    required double line,
    required FontWeight weight,
    double tracking = 0,
    bool isTabular = false,
  }) => withWeight(
    TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: size,
      height: line / size,
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

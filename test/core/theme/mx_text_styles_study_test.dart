import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// The study session's type roles (FE-A6 P1c), from the kit's source:
// StudyScreenV3, SessionFooterHint, SessionStatusHero, ResultRow.
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(
    theme.textTheme,
    scheme,
    theme.extension<MxSemanticColors>()!,
  );

  void expectStyle(
    TextStyle style, {
    required double size,
    required FontWeight weight,
    double? tracking,
    Color? color,
  }) {
    expect(style.fontSize, size);
    expect(style.fontWeight, weight);
    expect(
      style.fontVariations,
      contains(FontVariation.weight(weight.value.toDouble())),
    );
    if (tracking != null) expect(style.letterSpacing, tracking);
    if (color != null) expect(style.color, color);
  }

  test('study faces: term 32/700 at -0.5, meaning 24/600 at -0.3, detail '
      '14/400 in the variant text (kit StudyScreenV3)', () {
    expectStyle(
      styles.studyTerm,
      size: 32,
      weight: FontWeight.w700,
      tracking: -0.5,
      color: scheme.onSurface,
    );
    expect(styles.studyTerm.height, 1.15);
    expectStyle(
      styles.studyMeaning,
      size: 24,
      weight: FontWeight.w600,
      tracking: -0.3,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.studyDetail,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.studyDetail.height, 1.5);
    expectStyle(
      styles.sessionHint,
      size: 12,
      weight: FontWeight.w400,
      tracking: 0.3,
      color: scheme.onSurfaceVariant,
    );
  });

  test('summary: title 24/700 at -0.4, the body strong run at 700 in '
      'onSurface, a fact value 16/700 tabular in its colour', () {
    expectStyle(
      styles.summaryTitle,
      size: 24,
      weight: FontWeight.w700,
      tracking: -0.4,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.summaryBodyStrong,
      size: styles.emptyBody.fontSize!,
      weight: FontWeight.w700,
      color: scheme.onSurface,
    );
    const foreground = Color(0xFF123456);
    final value = styles.factValue(foreground);
    expectStyle(value, size: 16, weight: FontWeight.w700, color: foreground);
    expect(value.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test(
    'guess option 16/500 at -0.1 and its letter 12/700; match term '
    '18/700 at -0.4 and meaning 14/600, all in the given foreground (FE-A6 P3)',
    () {
      const foreground = Color(0xFF123456);
      expectStyle(
        styles.studyOption(foreground),
        size: 16,
        weight: FontWeight.w500,
        tracking: -0.1,
        color: foreground,
      );
      expect(styles.studyOption(foreground).height, 1.25);
      expectStyle(
        styles.studyOptionLetter(foreground),
        size: 12,
        weight: FontWeight.w700,
        color: foreground,
      );
      expectStyle(
        styles.matchTerm(foreground),
        size: 18,
        weight: FontWeight.w700,
        tracking: -0.4,
        color: foreground,
      );
      expectStyle(
        styles.matchMeaning(foreground),
        size: 14,
        weight: FontWeight.w600,
        color: foreground,
      );
    },
  );

  test('recall and fill: the passage is 16/400 at 1.55, the fill answer '
      '24/700 at -0.3, struck through when wrong (FE-A6 P4)', () {
    expectStyle(
      styles.studyPassage,
      size: 16,
      weight: FontWeight.w400,
      color: scheme.onSurface,
    );
    expect(styles.studyPassage.height, 1.55);
    final foreground = scheme.error;
    final struck = styles.fillAnswer(foreground, isStruck: true);
    expectStyle(struck, size: 24, weight: FontWeight.w700, tracking: -0.3);
    expect(struck.color, foreground);
    expect(struck.decoration, TextDecoration.lineThrough);
    expect(struck.decorationColor, foreground);
    expect(
      styles.fillAnswer(foreground, isStruck: false).decoration,
      isNot(TextDecoration.lineThrough),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Component type treatments, each from its widget contract.
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme);

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

  test('button labels: 14/600 and 12/600, both at 0.1 tracking', () {
    expectStyle(
      styles.buttonLabel,
      size: 14,
      weight: FontWeight.w600,
      tracking: 0.1,
    );
    expectStyle(
      styles.buttonLabelSmall,
      size: 12,
      weight: FontWeight.w600,
      tracking: 0.1,
    );
  });

  test('app-bar titles: content 16/700/-0.3, screen 24/700/-0.5', () {
    expectStyle(
      styles.contentTitle,
      size: 16,
      weight: FontWeight.w700,
      tracking: -0.3,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.screenTitle,
      size: 24,
      weight: FontWeight.w700,
      tracking: -0.5,
      color: scheme.onSurface,
    );
  });

  test('empty state: title 20/700/-0.3, compact 16/700, body 14 at 1.55', () {
    expectStyle(
      styles.emptyTitle,
      size: 20,
      weight: FontWeight.w700,
      tracking: -0.3,
    );
    expectStyle(styles.emptyTitleCompact, size: 16, weight: FontWeight.w700);
    expectStyle(
      styles.emptyBody,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.emptyBody.height, 1.55);
  });

  test('breadcrumb: ancestor 12/500, current 12/700, 0.1 tracking', () {
    expectStyle(
      styles.breadcrumbAncestor,
      size: 12,
      weight: FontWeight.w500,
      tracking: 0.1,
      color: scheme.onSurfaceVariant,
    );
    expectStyle(
      styles.breadcrumbCurrent,
      size: 12,
      weight: FontWeight.w700,
      tracking: 0.1,
      color: scheme.onSurface,
    );
  });

  test('study bar: badge 12/700 in the accent, counter tabular', () {
    const accent = Color(0xFF123456);
    expectStyle(
      styles.studyBadge(accent),
      size: 12,
      weight: FontWeight.w700,
      tracking: 1.2,
      color: accent,
    );
    expect(
      styles.counter.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(styles.counter.color, scheme.onSurfaceVariant);
  });

  test('nav label is primary only when selected', () {
    expect(styles.navLabel(isSelected: true).color, scheme.primary);
    expect(styles.navLabel(isSelected: false).color, scheme.onSurfaceVariant);
    expectStyle(
      styles.navLabel(isSelected: true),
      size: 12,
      weight: FontWeight.w600,
    );
  });

  test('footer caption is 12 onSurfaceVariant', () {
    expectStyle(
      styles.footerCaption,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
  });

  test('chip count 12/700 tabular in the given ink', () {
    const ink = Color(0xFF654321);
    expectStyle(
      styles.chipCount(ink),
      size: 12,
      weight: FontWeight.w700,
      tracking: 0.1,
      color: ink,
    );
    expect(
      styles.chipCount(ink).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('field message is the caption role in the given ink', () {
    const ink = Color(0xFF654321);
    expectStyle(
      styles.fieldMessage(ink),
      size: 12,
      weight: FontWeight.w600,
      color: ink,
    );
  });

  test('input hint 14 onSurfaceVariant; search value 16/400', () {
    expectStyle(
      styles.inputHint,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    expectStyle(
      styles.searchValue,
      size: 16,
      weight: FontWeight.w400,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.searchHint,
      size: 16,
      weight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
  });

  test('option row: title 14/600/-0.1, description 12 at 1.45', () {
    expectStyle(
      styles.optionTitle,
      size: 14,
      weight: FontWeight.w600,
      tracking: -0.1,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.optionDescription,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.optionDescription.height, 1.45);
  });

  test('tray label follows selection; stepper value 16/700 tabular', () {
    expect(styles.trayLabel(isSelected: true).color, scheme.onSurface);
    expect(styles.trayLabel(isSelected: false).color, scheme.onSurfaceVariant);
    expectStyle(
      styles.stepperValue(isInvalid: false),
      size: 16,
      weight: FontWeight.w700,
      color: scheme.onSurface,
    );
    expect(styles.stepperValue(isInvalid: true).color, scheme.error);
    expect(
      styles.stepperValue(isInvalid: false).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}

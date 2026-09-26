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

  // Stacked Vietnamese marks (Ẳ, Ổ, Ỗ) rise well above the font's ascent;
  // an ellipsized line clips at its box, and below 1.5 the box cuts them (Ổ
  // reads as Ố). Measured in the golden container.
  test('ellipsized single-line styles keep a 1.5 line box', () {
    for (final style in [
      styles.screenTitle,
      styles.listRowTitle,
      styles.rowTitleMatch,
      styles.rowSubtitle,
      styles.tagLabel,
      styles.removableTagLabel,
    ]) {
      expect(style.height, 1.5);
    }
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

  test('row styles: title 14/600/-0.1, list title at 1.5, sub-lines 12', () {
    expectStyle(
      styles.rowTitle,
      size: 14,
      weight: FontWeight.w600,
      tracking: -0.1,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.listRowTitle,
      size: 14,
      weight: FontWeight.w600,
      tracking: -0.1,
    );
    expect(styles.listRowTitle.height, 1.5);
    expectStyle(
      styles.rowDescription,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.rowDescription.height, 1.45);
    expectStyle(
      styles.rowSubtitle,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
  });

  test('settings label 16/600/-0.1; a destructive command label is error', () {
    expectStyle(
      styles.settingsLabel,
      size: 16,
      weight: FontWeight.w600,
      tracking: -0.1,
      color: scheme.onSurface,
    );
    expect(styles.commandLabel(isDestructive: false).color, scheme.onSurface);
    expectStyle(
      styles.commandLabel(isDestructive: true),
      size: 14,
      weight: FontWeight.w600,
      color: scheme.error,
    );
  });

  test('overline 12/700 at 0.6, tabular, onSurfaceVariant', () {
    expectStyle(
      styles.overline,
      size: 12,
      weight: FontWeight.w700,
      tracking: 0.6,
      color: scheme.onSurfaceVariant,
    );
    expect(
      styles.overline.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('pills: badge 12/700 tabular at 1, tag 12/600 at 1.5, both 0.1', () {
    final badge = styles.badgeLabel(scheme.primary);
    expectStyle(
      badge,
      size: 12,
      weight: FontWeight.w700,
      tracking: 0.1,
      color: scheme.primary,
    );
    expect(badge.height, 1);
    expect(badge.fontFeatures, contains(const FontFeature.tabularFigures()));
    expectStyle(
      styles.tagLabel,
      size: 12,
      weight: FontWeight.w600,
      tracking: 0.1,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.tagLabel.height, 1.5);
  });

  test('note 12 at 1.5; workload 12/400 with 600 terms; donut 9/700', () {
    expectStyle(
      styles.noteText,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.noteText.height, 1.5);
    expectStyle(
      styles.workloadText,
      size: 12,
      weight: FontWeight.w400,
      tracking: 0.1,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.workloadText.height, 1.5);
    expect(
      styles.workloadText.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expectStyle(
      styles.workloadTerm(scheme.primary),
      size: 12,
      weight: FontWeight.w600,
      color: scheme.primary,
    );
    expectStyle(
      styles.donutLabel(scheme.primary),
      size: 9,
      weight: FontWeight.w700,
      color: scheme.primary,
    );
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

  test('compact title 16/700/-0.2; dialog body 14 onSurface', () {
    expectStyle(
      styles.compactTitle,
      size: 16,
      weight: FontWeight.w700,
      tracking: -0.2,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.dialogBody,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onSurface,
    );
  });

  test('banner: 12/700 title and a 12 message at 1.55, lead or detail', () {
    expectStyle(
      styles.bannerTitle,
      size: 12,
      weight: FontWeight.w700,
      color: scheme.onSurface,
    );
    expect(styles.bannerTitle.height, 1.55);
    expect(styles.bannerMessage(isLead: true).color, scheme.onSurface);
    expectStyle(
      styles.bannerMessage(isLead: false),
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.bannerMessage(isLead: false).height, 1.55);
  });

  test('snackbar: 14 message at 1.4, 14/700 inverse-primary action', () {
    expectStyle(
      styles.snackbarMessage,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onInverseSurface,
    );
    expect(styles.snackbarMessage.height, 1.4);
    expectStyle(
      styles.snackbarAction,
      size: 14,
      weight: FontWeight.w700,
      color: scheme.inversePrimary,
    );
  });

  test('rowTitleMatch is the list row title, bold, in primary', () {
    expect(styles.rowTitleMatch.fontSize, styles.listRowTitle.fontSize);
    expect(styles.rowTitleMatch.height, styles.listRowTitle.height);
    expect(styles.rowTitleMatch.fontWeight, FontWeight.w700);
    expect(styles.rowTitleMatch.color, AppColorSchemes.light.primary);
  });

  test('card editor field roles (kit 08/09)', () {
    expectStyle(
      styles.fieldTerm,
      size: 24,
      weight: FontWeight.w700,
      tracking: -0.4,
    );
    expect(styles.fieldTerm.height, 1.25);
    expectStyle(
      styles.fieldTermLong,
      size: 18,
      weight: FontWeight.w700,
      tracking: -0.4,
    );
    expectStyle(
      styles.fieldTermHint,
      size: 16,
      weight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    expectStyle(styles.fieldMeaning, size: 16, weight: FontWeight.w500);
    expect(styles.fieldMeaning.height, 1.45);
    expectStyle(styles.fieldDetail, size: 14, weight: FontWeight.w400);
    expect(styles.fieldDetail.height, 1.45);
  });

  test('sentences at caption size carry no tracking (kit components)', () {
    for (final style in [
      styles.fieldMessage(scheme.error),
      styles.footerCaption,
      styles.rowDescription,
      styles.noteText,
      styles.bannerMessage(isLead: false),
      styles.counter,
    ]) {
      expect(style.letterSpacing, 0);
    }
    expect(styles.studyBadge(scheme.primary).letterSpacing, 1.2);
    expect(styles.fieldCount(isOver: false).letterSpacing, 0.2);
    expect(styles.fieldCount(isOver: true).letterSpacing, 0.2);
  });

  test('statValue is tabular in the ink given; statLabel is the overline '
      '(FE-A6 D17)', () {
    final value = styles.statValue(const Color(0xFF123456));

    expect(value.color, const Color(0xFF123456));
    expect(value.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(styles.statLabel, styles.overline);
  });

  test('study faces: term 32/700 at -0.5, meaning 24/600 at -0.3, detail '
      '14/400 in the variant ink (kit StudyScreenV3)', () {
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
      'onSurface, a fact value 16/700 tabular in its ink', () {
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
    const ink = Color(0xFF123456);
    final value = styles.factValue(ink);
    expectStyle(value, size: 16, weight: FontWeight.w700, color: ink);
    expect(value.fontFeatures, contains(const FontFeature.tabularFigures()));
  });
}

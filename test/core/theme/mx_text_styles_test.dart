import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Component type treatments ("Flashcard Color Tokens" §3.3): each style is
// exactly one TextTheme role, its size, line height, weight and tracking
// untouched; only the colour is the component's. The table of §3.3 is pinned
// in flashcard_tokens_spec_test.dart; this file pins every style's role and
// colour, the styles the table leaves out included.
void main() {
  final theme = buildLightTheme();
  final texts = theme.textTheme;
  final scheme = AppColorSchemes.light;
  const semantic = MxSemanticColors.light;
  final styles = MxTextStyles(texts, scheme, semantic);
  const foreground = Color(0xFF123456);

  void expectRole(TextStyle style, TextStyle? role, {Color? color}) {
    expect(style.fontFamily, role!.fontFamily);
    expect(style.fontSize, role.fontSize);
    expect(style.height, role.height);
    expect(style.fontWeight, role.fontWeight);
    expect(style.fontVariations, role.fontVariations);
    expect(style.letterSpacing, role.letterSpacing);
    expect(style.fontFeatures, role.fontFeatures);
    if (color != null) expect(style.color, color);
  }

  test('buttons: labelLarge at every size, the detail labelMedium', () {
    expectRole(styles.buttonLabel, texts.labelLarge);
    expectRole(styles.buttonLabelSmall, texts.labelLarge);
    // Built without a colour, so the button's foreground reaches it.
    expectRole(styles.buttonDetail, texts.labelMedium);
    expect(styles.buttonDetail.color, isNull);
  });

  test('app-bar titles: content titleMedium, screen titleLarge', () {
    expectRole(styles.contentTitle, texts.titleMedium, color: scheme.onSurface);
    expectRole(styles.screenTitle, texts.titleLarge, color: scheme.onSurface);
  });

  test('empty state: titleMedium, compact titleSmall, body bodyMedium', () {
    expectRole(styles.emptyTitle, texts.titleMedium, color: scheme.onSurface);
    expectRole(
      styles.emptyTitleCompact,
      texts.titleSmall,
      color: scheme.onSurface,
    );
    expectRole(
      styles.emptyBody,
      texts.bodyMedium,
      color: scheme.onSurfaceVariant,
    );
    expectRole(
      styles.emptyBodyStrong,
      texts.titleSmall,
      color: scheme.onSurface,
    );
  });

  test('breadcrumb: ancestor labelMedium, current titleSmall', () {
    expectRole(
      styles.breadcrumbAncestor,
      texts.labelMedium,
      color: scheme.onSurfaceVariant,
    );
    expectRole(
      styles.breadcrumbCurrent,
      texts.titleSmall,
      color: scheme.onSurface,
    );
  });

  test('study bar: badge labelSmall in the accent, counter labelSmall', () {
    expectRole(
      styles.studyBadge(foreground),
      texts.labelSmall,
      color: foreground,
    );
    expectRole(
      styles.counter,
      texts.labelSmall,
      color: scheme.onSurfaceVariant,
    );
  });

  test('nav label: labelSmall, onSurface when selected (spec §6)', () {
    expectRole(
      styles.navLabel(isSelected: true),
      texts.labelSmall,
      color: scheme.onSurface,
    );
    expectRole(
      styles.navLabel(isSelected: false),
      texts.labelSmall,
      color: scheme.onSurfaceVariant,
    );
  });

  test('captions and pills: labelSmall in their foreground', () {
    expectRole(
      styles.footerCaption,
      texts.labelSmall,
      color: scheme.onSurfaceVariant,
    );
    expectRole(
      styles.chipCount(foreground),
      texts.labelSmall,
      color: foreground,
    );
    expectRole(
      styles.fieldMessage(foreground),
      texts.labelSmall,
      color: foreground,
    );
    expectRole(
      styles.badgeLabel(foreground),
      texts.labelSmall,
      color: foreground,
    );
    expectRole(
      styles.statusLabel(foreground),
      texts.labelSmall,
      color: foreground,
    );
    expectRole(
      styles.captionIn(foreground),
      texts.labelSmall,
      color: foreground,
    );
    expectRole(
      styles.tagLabel,
      texts.labelSmall,
      color: semantic.onNeutralSoft,
    );
    expectRole(
      styles.removableTagLabel,
      texts.labelSmall,
      color: semantic.onPrimarySoft,
    );
    expectRole(styles.historyAgo, texts.labelSmall, color: scheme.onSurface);
    expectRole(
      styles.donutLabel(foreground),
      texts.labelSmall,
      color: foreground,
    );
  });

  test('field and search: hint bodyMedium, search labelMedium, code digit '
      'displaySmall', () {
    expectRole(
      styles.inputHint,
      texts.bodyMedium,
      color: scheme.onSurfaceVariant,
    );
    expectRole(styles.searchValue, texts.labelMedium, color: scheme.onSurface);
    expectRole(
      styles.searchHint,
      texts.labelMedium,
      color: scheme.onSurfaceVariant,
    );
    expectRole(styles.fieldCode, texts.displaySmall, color: scheme.onSurface);
    expectRole(styles.fieldLabel, texts.labelMedium, color: scheme.onSurface);
    expectRole(
      styles.fieldCount(isOver: false),
      texts.labelSmall,
      color: scheme.onSurfaceVariant,
    );
    expectRole(
      styles.fieldCount(isOver: true),
      texts.labelSmall,
      color: scheme.error,
    );
    expectRole(
      styles.disclosureLabel,
      texts.labelMedium,
      color: semantic.primaryText,
    );
  });

  test('rows: titles titleSmall, sub-lines bodyMedium', () {
    for (final title in [
      styles.rowTitle,
      styles.listRowTitle,
      styles.settingsLabel,
    ]) {
      expectRole(title, texts.titleSmall, color: scheme.onSurface);
    }
    expectRole(
      styles.rowTitleMatch,
      texts.titleSmall,
      color: semantic.primaryText,
    );
    for (final line in [styles.rowDescription, styles.rowSubtitle]) {
      expectRole(line, texts.bodyMedium, color: scheme.onSurfaceVariant);
    }
    expectRole(
      styles.commandLabel(isDestructive: false),
      texts.titleSmall,
      color: scheme.onSurface,
    );
    expectRole(
      styles.commandLabel(isDestructive: true),
      texts.titleSmall,
      color: scheme.error,
    );
    expectRole(
      styles.historyMove(foreground),
      texts.bodyMedium,
      color: foreground,
    );
  });

  test('overline and eyebrow: labelSmall', () {
    expectRole(styles.overline, texts.labelSmall, color: scheme.onSurface);
    expectRole(
      styles.eyebrow,
      texts.labelSmall,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.statLabel, styles.eyebrow);
  });

  test('notes and workload: bodyMedium and labelMedium', () {
    expectRole(
      styles.noteText,
      texts.bodyMedium,
      color: scheme.onSurfaceVariant,
    );
    expectRole(
      styles.statusNote(foreground),
      texts.bodyMedium,
      color: foreground,
    );
    expectRole(
      styles.requiredMarker,
      texts.bodyMedium,
      color: semantic.primaryText,
    );
    expectRole(
      styles.workloadText,
      texts.labelMedium,
      color: scheme.onSurfaceVariant,
    );
    expectRole(
      styles.workloadTerm(foreground),
      texts.labelMedium,
      color: foreground,
    );
  });

  test('figures: a stat displayMedium, a fact and a stepper titleMedium', () {
    expectRole(
      styles.statValue(foreground),
      texts.displayMedium,
      color: foreground,
    );
    expect(styles.statValue(foreground).fontFeatures, const [
      FontFeature.tabularFigures(),
    ]);
    expectRole(
      styles.factValue(foreground),
      texts.titleMedium,
      color: foreground,
    );
    expectRole(
      styles.stepperValue(isInvalid: false),
      texts.titleMedium,
      color: scheme.onSurface,
    );
    expectRole(
      styles.stepperValue(isInvalid: true),
      texts.titleMedium,
      color: scheme.error,
    );
  });

  test('tray and steps: labelSmall, onSurface when current', () {
    for (final (on, off) in [
      (styles.trayLabel(isSelected: true), styles.trayLabel(isSelected: false)),
      (styles.stepLabel(isReached: true), styles.stepLabel(isReached: false)),
      (styles.dayLabel(isCurrent: true), styles.dayLabel(isCurrent: false)),
    ]) {
      expectRole(on, texts.labelSmall, color: scheme.onSurface);
      expectRole(off, texts.labelSmall, color: scheme.onSurfaceVariant);
    }
    expectRole(
      styles.stepNumber(foreground),
      texts.labelSmall,
      color: foreground,
    );
  });

  test('dialog, banner and snackbar', () {
    expectRole(styles.compactTitle, texts.titleSmall, color: scheme.onSurface);
    expectRole(styles.dialogBody, texts.bodyMedium, color: scheme.onSurface);
    expectRole(styles.bannerTitle, texts.labelMedium, color: scheme.onSurface);
    expectRole(
      styles.bannerMessage(isLead: true),
      texts.labelMedium,
      color: scheme.onSurface,
    );
    expectRole(
      styles.bannerMessage(isLead: false),
      texts.labelMedium,
      color: scheme.onSurfaceVariant,
    );
    expectRole(
      styles.snackbarMessage,
      texts.bodyMedium,
      color: scheme.onInverseSurface,
    );
    expectRole(
      styles.snackbarAction,
      texts.labelLarge,
      color: scheme.inversePrimary,
    );
  });

  test('nothing is below the 12 floor', () {
    for (final style in [
      styles.counter,
      styles.donutLabel(foreground),
      styles.badgeLabel(foreground),
      styles.footerCaption,
    ]) {
      expect(style.fontSize, greaterThanOrEqualTo(12));
    }
  });
}

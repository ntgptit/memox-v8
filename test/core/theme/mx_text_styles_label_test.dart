import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// The labelling styles (critique 2026-09-30 part 2, P1 to P3) as single
// roles ("Flashcard Color Tokens" §3.3).
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme, MxSemanticColors.light);

  test('eyebrow: labelSmall, onSurfaceVariant (P2)', () {
    final eyebrow = styles.eyebrow;
    expect(eyebrow.fontSize, 12);
    expect(eyebrow.fontWeight, FontWeight.w500);
    expect(eyebrow.letterSpacing, 0.5);
    expect(eyebrow.color, scheme.onSurfaceVariant);
  });

  test('field label: labelMedium, onSurface (P3)', () {
    expect(styles.fieldLabel.fontSize, 14);
    expect(styles.fieldLabel.fontWeight, FontWeight.w400);
    expect(styles.fieldLabel.color, scheme.onSurface);
  });

  test('Required is the row description in primary text (P3)', () {
    expect(styles.requiredMarker.fontSize, styles.rowDescription.fontSize);
    expect(styles.requiredMarker.fontWeight, styles.rowDescription.fontWeight);
    expect(styles.requiredMarker.color, MxSemanticColors.light.primaryText);
  });

  test('a stat label is the eyebrow (P1)', () {
    expect(styles.statLabel, styles.eyebrow);
  });
}

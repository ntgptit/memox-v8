import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// The three label roles (critique 2026-09-30 part 2, P1–P3).
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(
    theme.textTheme,
    scheme,
    theme.extension<MxSemanticColors>()!,
  );

  test('eyebrow: 12/600 at 0.8, tabular, onSurfaceVariant (P2)', () {
    final eyebrow = styles.eyebrow;
    expect(eyebrow.fontSize, 12);
    expect(eyebrow.fontWeight, FontWeight.w600);
    expect(eyebrow.letterSpacing, 0.8);
    expect(eyebrow.color, scheme.onSurfaceVariant);
    expect(eyebrow.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test('field label: 14/600 onSurface (P3)', () {
    expect(styles.fieldLabel.fontSize, 14);
    expect(styles.fieldLabel.fontWeight, FontWeight.w600);
    expect(styles.fieldLabel.color, scheme.onSurface);
  });

  test('Required is the optional caption in primary ink (P3)', () {
    expect(styles.requiredMarker.fontSize, styles.rowDescription.fontSize);
    expect(styles.requiredMarker.fontWeight, styles.rowDescription.fontWeight);
    expect(
      styles.requiredMarker.color,
      theme.extension<MxSemanticColors>()!.primaryText,
    );
  });

  test('a stat label is the eyebrow (P1)', () {
    expect(styles.statLabel, styles.eyebrow);
  });
}

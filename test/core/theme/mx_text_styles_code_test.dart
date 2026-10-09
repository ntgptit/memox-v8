import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Monitoring (owner 2026-09-29): the code style for stack traces and JSON.
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme, MxSemanticColors.light);

  test('code is the system monospace at the caption size, no tracking', () {
    final code = styles.code;

    expect(code.fontFamily, 'monospace');
    expect(code.fontFamilyFallback, contains('Menlo'));
    expect(code.fontSize, theme.textTheme.bodySmall!.fontSize);
    expect(code.letterSpacing, 0);
    expect(code.color, scheme.onSurface);
  });

  test('code has tabular figures and no wght axis of the app font', () {
    final code = styles.code;

    expect(code.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(code.fontVariations, isEmpty);
  });

  test('code keeps a 1.5 line box, so a wrapped trace never clips', () {
    expect(styles.code.height, 1.5);
  });
}

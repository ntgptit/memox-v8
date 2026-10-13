import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Monitoring (owner 2026-09-29): the code style for stack traces and JSON,
// bodyMedium in the system monospace ("Flashcard Color Tokens" §3.3).
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme, MxSemanticColors.light);
  final body = theme.textTheme.bodyMedium!;

  test('code is the system monospace at bodyMedium', () {
    final code = styles.code;

    expect(code.fontFamily, 'monospace');
    expect(code.fontFamilyFallback, contains('Menlo'));
    expect(code.fontSize, body.fontSize);
    expect(code.height, body.height);
    expect(code.letterSpacing, body.letterSpacing);
    expect(code.color, scheme.onSurface);
  });

  test('code has no wght axis of the app font', () {
    expect(styles.code.fontVariations, isEmpty);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// The study session's type roles (FE-A6 P1c) as the spec's content roles
// ("Flashcard Color Tokens" §3.2, §3.3): the term displaySmall, the meaning
// and passage bodyLarge, a match term headlineSmall, a tile's meaning
// bodySmall, all at no tracking.
void main() {
  final theme = buildLightTheme();
  final texts = theme.textTheme;
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(texts, scheme, MxSemanticColors.light);
  const foreground = Color(0xFF123456);

  void expectRole(TextStyle style, TextStyle? role, Color color) {
    expect(style.fontSize, role!.fontSize);
    expect(style.height, role.height);
    expect(style.fontWeight, role.fontWeight);
    expect(style.letterSpacing, role.letterSpacing);
    expect(style.color, color);
  }

  test('study faces: term displaySmall, meaning bodyLarge, detail and hint '
      'bodyMedium', () {
    expectRole(styles.studyTerm, texts.displaySmall, scheme.onSurface);
    expectRole(styles.studyMeaning, texts.bodyLarge, scheme.onSurface);
    expectRole(styles.studyDetail, texts.bodyMedium, scheme.onSurfaceVariant);
    expectRole(styles.sessionHint, texts.bodyMedium, scheme.onSurfaceVariant);
  });

  test('study content carries no tracking', () {
    for (final style in [
      styles.studyTerm,
      styles.studyMeaning,
      styles.studyPassage,
      styles.matchTerm(foreground),
      styles.matchMeaning(foreground),
      styles.studyOption(foreground),
    ]) {
      expect(style.letterSpacing, 0);
    }
  });

  test(
    'summary: title titleMedium, strong run titleSmall, fact titleMedium',
    () {
      expectRole(styles.summaryTitle, texts.titleMedium, scheme.onSurface);
      expectRole(styles.summaryBodyStrong, texts.titleSmall, scheme.onSurface);
      expectRole(styles.factValue(foreground), texts.titleMedium, foreground);
    },
  );

  test('guess and match: a term headlineSmall, a meaning bodySmall, the '
      'letter labelSmall, in the tone foreground', () {
    expectRole(styles.studyOption(foreground), texts.bodySmall, foreground);
    expectRole(
      styles.studyOptionLetter(foreground),
      texts.labelSmall,
      foreground,
    );
    expectRole(styles.matchTerm(foreground), texts.headlineSmall, foreground);
    expectRole(styles.matchMeaning(foreground), texts.bodySmall, foreground);
  });

  test('recall and fill: the passage bodyLarge, the fill answer displaySmall '
      'struck in its foreground', () {
    expectRole(styles.studyPassage, texts.bodyLarge, scheme.onSurface);
    final struck = styles.fillAnswer(foreground, isStruck: true);
    expectRole(struck, texts.displaySmall, foreground);
    expect(struck.decoration, TextDecoration.lineThrough);
    expect(struck.decorationColor, foreground);
    final kept = styles.fillAnswer(foreground, isStruck: false);
    expect(kept.decoration, isNot(TextDecoration.lineThrough));
  });
}

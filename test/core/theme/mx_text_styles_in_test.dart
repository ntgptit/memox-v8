import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// The `*In(ink)` accessors: a rung on a container, in its on-container.
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme, MxSemanticColors.light);

  test('each *In(ink) is its rung with only the colour changed', () {
    const ink = Color(0xFF123456);
    final pairs = <String, (TextStyle, TextStyle)>{
      'eyebrowIn': (styles.eyebrowIn(ink), styles.eyebrow),
      'summaryTitleIn': (styles.summaryTitleIn(ink), styles.summaryTitle),
      'emptyBodyIn': (styles.emptyBodyIn(ink), styles.emptyBody),
      'summaryBodyStrongIn': (
        styles.summaryBodyStrongIn(ink),
        styles.summaryBodyStrong,
      ),
      'noteTextIn': (styles.noteTextIn(ink), styles.noteText),
    };
    for (final entry in pairs.entries) {
      final (inked, base) = entry.value;
      expect(inked.color, ink, reason: entry.key);
      expect(inked, base.copyWith(color: ink), reason: entry.key);
      expect(inked.fontSize, base.fontSize, reason: entry.key);
      expect(inked.fontWeight, base.fontWeight, reason: entry.key);
      expect(inked.height, base.height, reason: entry.key);
      expect(inked.letterSpacing, base.letterSpacing, reason: entry.key);
    }
    // A null ink (a plain card's neutral roles) leaves the rung as it is.
    expect(styles.eyebrowIn(null), styles.eyebrow);
    expect(styles.emptyBodyIn(null), styles.emptyBody);
  });
}

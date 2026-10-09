import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Primary as text reads in primaryForeground, never the fill.
void main() {
  for (final (scheme, semantic, name) in [
    (AppColorSchemes.light, MxSemanticColors.light, 'light'),
    (AppColorSchemes.dark, MxSemanticColors.dark, 'dark'),
  ]) {
    final styles = MxTextStyles(
      ThemeData(colorScheme: scheme).textTheme,
      scheme,
      semantic,
    );
    test('$name brand text reads in primaryForeground, never primary', () {
      for (final style in [
        styles.disclosureLabel,
        styles.rowTitleMatch,
        styles.requiredMarker,
        styles.navLabel(isSelected: true),
      ]) {
        expect(style.color, semantic.primaryForeground);
      }
      expect(styles.navLabel(isSelected: false).color, scheme.onSurfaceVariant);
      // The removable tag chip becomes a primaryContainer pill (task 14).
      expect(styles.removableTagLabel.color, scheme.onPrimaryContainer);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

void main() {
  for (final (scheme, semantic, name) in [
    (AppColorSchemes.light, MxSemanticColors.light, 'light'),
    (AppColorSchemes.dark, MxSemanticColors.dark, 'dark'),
  ]) {
    final isDark = scheme.brightness == Brightness.dark;
    Color? edge(BoxDecoration d) => (d.border as Border?)?.top.color;

    test('$name raised card: lowest, outlineVariant hairline in dark only', () {
      final d = AppDecorations.raisedCard(scheme);
      expect(d.color, scheme.surfaceContainerLowest);
      expect(edge(d), isDark ? scheme.outlineVariant : null);
    });

    test('$name recessed card: low, outlineVariant hairline, no shadow', () {
      final d = AppDecorations.recessedCard(scheme);
      expect(d.color, scheme.surfaceContainerLow);
      expect(edge(d), scheme.outlineVariant);
      expect(d.boxShadow, isEmpty);
    });

    test(
      '$name hero card (V4b): low, outlineVariant hairline, raised shadow',
      () {
        final d = AppDecorations.heroCard(scheme);
        expect(d.color, scheme.surfaceContainerLow);
        expect(edge(d), scheme.outlineVariant);
        expect(d.boxShadow, AppDecorations.raisedCard(scheme).boxShadow);
      },
    );

    test(
      '$name warning / success / danger cards are containers without an edge',
      () {
        expect(
          AppDecorations.warningCard(scheme, semantic).color,
          semantic.warningContainer,
        );
        expect(edge(AppDecorations.warningCard(scheme, semantic)), null);
        expect(
          AppDecorations.successCard(scheme, semantic).color,
          semantic.successContainer,
        );
        expect(edge(AppDecorations.successCard(scheme, semantic)), null);
        expect(AppDecorations.dangerCard(scheme).color, scheme.errorContainer);
        expect(edge(AppDecorations.dangerCard(scheme)), null);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Card contract: the card ground at radius 12, the border hairline in both
// themes (plan R2), the whisper shadow where the theme casts one.
void main() {
  for (final (theme, scheme, semantic) in [
    ('Day', AppColorSchemes.light, MxSemanticColors.light),
    ('Night', AppColorSchemes.dark, MxSemanticColors.dark),
  ]) {
    Border edge(Color color) =>
        Border.all(color: color, width: AppStroke.hairline);

    test('raised card draws the border hairline in $theme (R2)', () {
      final box = AppDecorations.raisedCard(scheme, semantic);

      expect(box.color, scheme.surfaceContainerLowest);
      expect(box.borderRadius, BorderRadius.circular(12));
      expect(box.border, edge(semantic.border));
      expect(box.boxShadow, AppShadows.whisper(scheme));
    });

    test('recessed card is the low ground, flat, in $theme', () {
      final box = AppDecorations.recessedCard(scheme, semantic);

      expect(box.color, scheme.surfaceContainerLow);
      expect(box.border, edge(semantic.border));
      expect(box.boxShadow, isEmpty);
    });

    test('hero card fills primaryContainer in $theme', () {
      final hero = AppDecorations.heroCard(scheme, semantic);

      expect(hero.color, scheme.primaryContainer);
      expect(hero.border, edge(semantic.border));
    });

    test('toned cards fill their soft token outright in $theme', () {
      final warning = AppDecorations.warningCard(scheme, semantic);
      final success = AppDecorations.successCard(scheme, semantic);
      final danger = AppDecorations.dangerCard(scheme, semantic);

      expect(warning.color, semantic.warningSoft);
      expect(warning.border, edge(semantic.warningBorder));
      expect(success.color, semantic.successSoft);
      expect(success.border, edge(semantic.successBorder));
      expect(danger.color, semantic.dangerSoft);
      expect(danger.border, edge(semantic.dangerBorder));
    });
  }
}

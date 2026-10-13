import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Card contract ("Flashcard Color Tokens" §6): each card is its ground at
// radius 12, with no edge and no shadow, the same in both themes.
void main() {
  for (final (theme, scheme, semantic) in [
    ('light', AppColorSchemes.light, MxSemanticColors.light),
    ('dark', AppColorSchemes.dark, MxSemanticColors.dark),
  ]) {
    void expectFlat(BoxDecoration box) {
      expect(box.borderRadius, BorderRadius.circular(12));
      expect(box.border, isNull);
      expect(box.boxShadow, isNull);
    }

    test('raised card is the card surface, flat, in $theme', () {
      final box = AppDecorations.raisedCard(scheme, semantic);

      expect(box.color, semantic.cardSurface);
      expectFlat(box);
    });

    test('recessed card is the low ground, flat, in $theme', () {
      final box = AppDecorations.recessedCard(scheme, semantic);

      expect(box.color, scheme.surfaceContainerLow);
      expectFlat(box);
    });

    test('hero card fills primaryContainer, flat, in $theme', () {
      final hero = AppDecorations.heroCard(scheme, semantic);

      expect(hero.color, scheme.primaryContainer);
      expectFlat(hero);
    });

    test('toned cards fill their soft token outright, flat, in $theme', () {
      final warning = AppDecorations.warningCard(scheme, semantic);
      final success = AppDecorations.successCard(scheme, semantic);
      final danger = AppDecorations.dangerCard(scheme, semantic);

      expect(warning.color, semantic.warningSoft);
      expect(success.color, semantic.successSoft);
      expect(danger.color, semantic.dangerSoft);
      for (final box in [warning, success, danger]) {
        expectFlat(box);
      }
    });
  }
}

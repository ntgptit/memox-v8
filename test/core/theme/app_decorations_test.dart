import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Card contract: surface-raised, radius 20, whisper shadow in light,
// 1px ghost border and no shadow in dark.
void main() {
  test('light: surface-raised with the whisper shadow and no border', () {
    final scheme = AppColorSchemes.light;
    final card = AppDecorations.raisedCard(
      scheme,
      MxDerivedColors.resolve(scheme, MxSemanticColors.light),
    );

    expect(card.color, scheme.surfaceContainerLowest);
    expect(card.borderRadius, BorderRadius.circular(12));
    expect(card.boxShadow, AppShadows.whisper(scheme));
    expect(card.border, isNull);
  });

  test('dark: a 1px ghost border and no shadow', () {
    final scheme = AppColorSchemes.dark;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.dark);
    final card = AppDecorations.raisedCard(scheme, derived);

    expect(card.boxShadow, isEmpty);
    expect(card.border, Border.all(color: derived.ghostBorder));
  });

  test('hero: surface-hero fill with the ghost edge in both themes', () {
    for (final (scheme, semantic) in [
      (AppColorSchemes.light, MxSemanticColors.light),
      (AppColorSchemes.dark, MxSemanticColors.dark),
    ]) {
      final derived = MxDerivedColors.resolve(scheme, semantic);
      final hero = AppDecorations.heroCard(scheme, derived);

      expect(hero.color, derived.surfaceHero);
      expect(hero.border, Border.all(color: derived.ghostBorder));
      expect(hero.borderRadius, BorderRadius.circular(12));
      expect(hero.boxShadow, AppShadows.whisper(scheme));
    }
  });

  test('the success and danger cards blend their soft tint over the raised '
      'fill and take their border (FE-A6 D14)', () {
    final scheme = AppColorSchemes.light;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    final raised = AppDecorations.raisedCard(scheme, derived).color!;

    final success = AppDecorations.successCard(scheme, derived);
    final danger = AppDecorations.dangerCard(scheme, derived);

    expect(success.color, Color.alphaBlend(derived.successSoft, raised));
    expect((success.border! as Border).top.color, derived.successBorder);
    expect(danger.color, Color.alphaBlend(derived.dangerSoft, raised));
    expect((danger.border! as Border).top.color, derived.dangerBorder);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

void main() {
  test('every TextTheme slot is Plus Jakarta Sans in its DESIGN.md role', () {
    final texts = buildLightTheme().textTheme;
    final slots = {
      'displayLarge': (texts.displayLarge, DesignTypeSlots.displayLarge),
      'displayMedium': (texts.displayMedium, DesignTypeSlots.displayMedium),
      'displaySmall': (texts.displaySmall, DesignTypeSlots.displaySmall),
      'headlineLarge': (texts.headlineLarge, DesignTypeSlots.headlineLarge),
      'headlineMedium': (texts.headlineMedium, DesignTypeSlots.headlineMedium),
      'headlineSmall': (texts.headlineSmall, DesignTypeSlots.headlineSmall),
      'titleLarge': (texts.titleLarge, DesignTypeSlots.titleLarge),
      'titleMedium': (texts.titleMedium, DesignTypeSlots.titleMedium),
      'titleSmall': (texts.titleSmall, DesignTypeSlots.titleSmall),
      'bodyLarge': (texts.bodyLarge, DesignTypeSlots.bodyLarge),
      'bodyMedium': (texts.bodyMedium, DesignTypeSlots.bodyMedium),
      'bodySmall': (texts.bodySmall, DesignTypeSlots.bodySmall),
      'labelLarge': (texts.labelLarge, DesignTypeSlots.labelLarge),
      'labelMedium': (texts.labelMedium, DesignTypeSlots.labelMedium),
      'labelSmall': (texts.labelSmall, DesignTypeSlots.labelSmall),
    };

    for (final MapEntry(key: slot, value: (style, spec)) in slots.entries) {
      expect(style!.fontFamily, DesignType.fontFamily, reason: slot);
      expect(style.fontSize, spec.size, reason: slot);
      expect(style.height, spec.height, reason: slot);
      expect(style.letterSpacing, spec.letterSpacing, reason: slot);
      expect(style.fontWeight, spec.weight, reason: slot);
    }
  });

  test('withWeight moves the variable font axis with the weight', () {
    final style = AppTypography.withWeight(const TextStyle(), FontWeight.w700);

    expect(style.fontWeight, FontWeight.w700);
    expect(style.fontVariations, [const FontVariation('wght', 700)]);
  });

  test('a tabular role draws tabular figures', () {
    expect(AppTypography.role(DesignType.stat).fontFeatures, [
      const FontFeature.tabularFigures(),
    ]);
    expect(AppTypography.role(DesignType.body).fontFeatures, isNull);
  });

  test('the text theme and the component styles are inked per theme', () {
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      final scheme = theme.colorScheme;
      final styles = theme.extension<MxTextStyles>()!;

      expect(theme.textTheme.bodyMedium!.color, scheme.onSurface);
      expect(styles.eyebrow.color, scheme.onSurfaceVariant);
      expect(styles.sectionLabel.color, scheme.onSurfaceVariant);
      expect(styles.fieldLabel.color, scheme.onSurface);
      expect(styles.buttonLabel.fontSize, DesignType.buttonLabel.size);
    }
  });
}

import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// DESIGN.md typography: one family (Plus Jakarta Sans, a variable font) and
/// the roles of the frontmatter, mapped onto Material 3's fifteen TextTheme
/// slots by `type-slots` (spec 2026-10-04-sp3a §5.2).
abstract final class AppTypography {
  /// The style of one DESIGN.md role, without a colour.
  static TextStyle role(DesignTypeSpec spec) => withWeight(
    TextStyle(
      fontFamily: DesignType.fontFamily,
      fontSize: spec.size,
      height: spec.height,
      letterSpacing: spec.letterSpacing,
      fontFeatures: spec.hasTabularFigures
          ? const [FontFeature.tabularFigures()]
          : null,
    ),
    spec.weight,
  );

  /// [style] at [weight]. The family is variable, so the `wght` axis moves
  /// with `fontWeight`; setting only `fontWeight` would draw the default
  /// instance at a synthetic weight.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );

  /// The fifteen Material 3 slots, each in its DESIGN.md role, inked in
  /// [scheme]'s `onSurface`.
  static TextTheme textTheme(ColorScheme scheme) => TextTheme(
    displayLarge: role(DesignTypeSlots.displayLarge),
    displayMedium: role(DesignTypeSlots.displayMedium),
    displaySmall: role(DesignTypeSlots.displaySmall),
    headlineLarge: role(DesignTypeSlots.headlineLarge),
    headlineMedium: role(DesignTypeSlots.headlineMedium),
    headlineSmall: role(DesignTypeSlots.headlineSmall),
    titleLarge: role(DesignTypeSlots.titleLarge),
    titleMedium: role(DesignTypeSlots.titleMedium),
    titleSmall: role(DesignTypeSlots.titleSmall),
    bodyLarge: role(DesignTypeSlots.bodyLarge),
    bodyMedium: role(DesignTypeSlots.bodyMedium),
    bodySmall: role(DesignTypeSlots.bodySmall),
    labelLarge: role(DesignTypeSlots.labelLarge),
    labelMedium: role(DesignTypeSlots.labelMedium),
    labelSmall: role(DesignTypeSlots.labelSmall),
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
}

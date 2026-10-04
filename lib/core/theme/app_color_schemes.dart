import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The Material 3 colour scheme of each theme, with all 45 roles set from
/// DESIGN.md through the generated palette (spec 2026-10-04-sp3a §5.2).
/// Never `fromSeed`: every role is the value DESIGN.md states.
final ColorScheme lightColorScheme = _scheme(
  DesignPalette.light,
  Brightness.light,
);

final ColorScheme darkColorScheme = _scheme(
  DesignPalette.dark,
  Brightness.dark,
);

ColorScheme _scheme(DesignPalette palette, Brightness brightness) =>
    ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
      tertiary: palette.tertiary,
      onTertiary: palette.onTertiary,
      tertiaryContainer: palette.tertiaryContainer,
      onTertiaryContainer: palette.onTertiaryContainer,
      error: palette.error,
      onError: palette.onError,
      errorContainer: palette.errorContainer,
      onErrorContainer: palette.onErrorContainer,
      surface: palette.surface,
      onSurface: palette.onSurface,
      onSurfaceVariant: palette.onSurfaceVariant,
      outline: palette.outline,
      outlineVariant: palette.outlineVariant,
      shadow: palette.shadow,
      scrim: palette.scrim,
      inverseSurface: palette.inverseSurface,
      onInverseSurface: palette.onInverseSurface,
      inversePrimary: palette.inversePrimary,
      primaryFixed: palette.primaryFixed,
      primaryFixedDim: palette.primaryFixedDim,
      onPrimaryFixed: palette.onPrimaryFixed,
      onPrimaryFixedVariant: palette.onPrimaryFixedVariant,
      secondaryFixed: palette.secondaryFixed,
      secondaryFixedDim: palette.secondaryFixedDim,
      onSecondaryFixed: palette.onSecondaryFixed,
      onSecondaryFixedVariant: palette.onSecondaryFixedVariant,
      tertiaryFixed: palette.tertiaryFixed,
      tertiaryFixedDim: palette.tertiaryFixedDim,
      onTertiaryFixed: palette.onTertiaryFixed,
      onTertiaryFixedVariant: palette.onTertiaryFixedVariant,
      surfaceDim: palette.surfaceDim,
      surfaceBright: palette.surfaceBright,
      surfaceContainerLowest: palette.surfaceContainerLowest,
      surfaceContainerLow: palette.surfaceContainerLow,
      surfaceContainer: palette.surfaceContainer,
      surfaceContainerHigh: palette.surfaceContainerHigh,
      surfaceContainerHighest: palette.surfaceContainerHighest,
    );

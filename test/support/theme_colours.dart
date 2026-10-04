import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// The 45 Material 3 roles of [scheme], keyed by their DESIGN.md name. The
/// guard's allowlist (`color_scheme_arguments_are_m3_roles`) is the same set.
Map<String, Color> schemeRoles(ColorScheme scheme) => {
  'primary': scheme.primary,
  'on-primary': scheme.onPrimary,
  'primary-container': scheme.primaryContainer,
  'on-primary-container': scheme.onPrimaryContainer,
  'secondary': scheme.secondary,
  'on-secondary': scheme.onSecondary,
  'secondary-container': scheme.secondaryContainer,
  'on-secondary-container': scheme.onSecondaryContainer,
  'tertiary': scheme.tertiary,
  'on-tertiary': scheme.onTertiary,
  'tertiary-container': scheme.tertiaryContainer,
  'on-tertiary-container': scheme.onTertiaryContainer,
  'error': scheme.error,
  'on-error': scheme.onError,
  'error-container': scheme.errorContainer,
  'on-error-container': scheme.onErrorContainer,
  'surface': scheme.surface,
  'on-surface': scheme.onSurface,
  'on-surface-variant': scheme.onSurfaceVariant,
  'outline': scheme.outline,
  'outline-variant': scheme.outlineVariant,
  'shadow': scheme.shadow,
  'scrim': scheme.scrim,
  'inverse-surface': scheme.inverseSurface,
  'on-inverse-surface': scheme.onInverseSurface,
  'inverse-primary': scheme.inversePrimary,
  'primary-fixed': scheme.primaryFixed,
  'primary-fixed-dim': scheme.primaryFixedDim,
  'on-primary-fixed': scheme.onPrimaryFixed,
  'on-primary-fixed-variant': scheme.onPrimaryFixedVariant,
  'secondary-fixed': scheme.secondaryFixed,
  'secondary-fixed-dim': scheme.secondaryFixedDim,
  'on-secondary-fixed': scheme.onSecondaryFixed,
  'on-secondary-fixed-variant': scheme.onSecondaryFixedVariant,
  'tertiary-fixed': scheme.tertiaryFixed,
  'tertiary-fixed-dim': scheme.tertiaryFixedDim,
  'on-tertiary-fixed': scheme.onTertiaryFixed,
  'on-tertiary-fixed-variant': scheme.onTertiaryFixedVariant,
  'surface-dim': scheme.surfaceDim,
  'surface-bright': scheme.surfaceBright,
  'surface-container-lowest': scheme.surfaceContainerLowest,
  'surface-container-low': scheme.surfaceContainerLow,
  'surface-container': scheme.surfaceContainer,
  'surface-container-high': scheme.surfaceContainerHigh,
  'surface-container-highest': scheme.surfaceContainerHighest,
};

/// Every colour one theme holds, keyed by its DESIGN.md name: the 45 roles
/// and the MemoX extension colours (spec D18: no ink palette).
Map<String, Color> coloursOf({
  required ColorScheme scheme,
  required MxSemanticColors semantic,
}) => {
  ...schemeRoles(scheme),
  'mastery': semantic.mastery,
  'on-mastery': semantic.onMastery,
  'success': semantic.success,
  'on-success': semantic.onSuccess,
  'success-container': semantic.successContainer,
  'on-success-container': semantic.onSuccessContainer,
  'warning': semantic.warning,
  'on-warning': semantic.onWarning,
  'warning-container': semantic.warningContainer,
  'on-warning-container': semantic.onWarningContainer,
  'status-new': semantic.statusNew,
  'status-learning': semantic.statusLearning,
  'status-reviewing': semantic.statusReviewing,
  'status-mastered': semantic.statusMastered,
  'streak': semantic.streak,
  'ghost-border': semantic.ghostBorder,
};

/// Every colour [theme] holds, keyed by its DESIGN.md name.
Map<String, Color> themeColours(ThemeData theme) => coloursOf(
  scheme: theme.colorScheme,
  semantic: theme.extension<MxSemanticColors>()!,
);

/// The WCAG 2 contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final high = la > lb ? la : lb;
  final low = la > lb ? lb : la;
  return (high + 0.05) / (low + 0.05);
}

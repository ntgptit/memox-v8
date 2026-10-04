import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
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

/// Every colour one theme holds, keyed by its DESIGN.md name: the 45 roles,
/// the MemoX semantic colours and the derived colours.
Map<String, Color> coloursOf({
  required ColorScheme scheme,
  required MxSemanticColors semantic,
  required MxDerivedColors derived,
}) => {
  ...schemeRoles(scheme),
  'mastery': semantic.mastery,
  'on-mastery': semantic.onMastery,
  'success': semantic.success,
  'warning': semantic.warning,
  'on-warning': semantic.onWarning,
  'warning-ink': semantic.warningInk,
  'error-fill': semantic.errorFill,
  'on-error-fill': semantic.onErrorFill,
  'status-new': semantic.statusNew,
  'status-learning': semantic.statusLearning,
  'status-reviewing': semantic.statusReviewing,
  'status-mastered': semantic.statusMastered,
  'streak': semantic.streak,
  'primary-ink': derived.primaryInk,
  'ghost-border': derived.ghostBorder,
  'outline-edge': derived.outlineEdge,
  'status-new-ink': derived.statusNewInk,
  'status-learning-ink': derived.statusLearningInk,
  'status-reviewing-ink': derived.statusReviewingInk,
  'status-mastered-ink': derived.statusMasteredInk,
  'success-ink': derived.successInk,
  'danger-ink': derived.dangerInk,
  'danger-tint': derived.dangerTint,
  'danger-tint-border': derived.dangerTintBorder,
  'warning-tint': derived.warningTint,
  'warning-tint-border': derived.warningTintBorder,
  'success-tint': derived.successTint,
  'success-tint-border': derived.successTintBorder,
};

/// The WCAG 2 contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final high = la > lb ? la : lb;
  final low = la > lb ? lb : la;
  return (high + 0.05) / (low + 0.05);
}

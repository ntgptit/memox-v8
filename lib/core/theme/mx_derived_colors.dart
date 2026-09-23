import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Colours derived from a role at a percentage (02-theme-binding
/// DERIVED_COLOR, BIND_NOW), plus the border-ghost edge colour.
///
/// Each derivation happens here exactly once. A component consuming one of
/// these applies no percentage of its own.
@immutable
final class MxDerivedColors {
  const MxDerivedColors._({
    required this.dangerSoft,
    required this.dangerBorder,
    required this.warningSoft,
    required this.surfaceHero,
    required this.chromeGlass,
    required this.ghostBorder,
  });

  factory MxDerivedColors.resolve(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) {
    final isDark = scheme.brightness == Brightness.dark;
    return MxDerivedColors._(
      dangerSoft: scheme.error.withValues(
        alpha: isDark ? _dangerSoftDark : _dangerSoftLight,
      ),
      dangerBorder: scheme.error.withValues(
        alpha: isDark ? _dangerBorderDark : _dangerBorderLight,
      ),
      warningSoft: semantic.warning.withValues(
        alpha: isDark ? _warningSoftDark : _warningSoftLight,
      ),
      // The one derivation whose base changes with the theme.
      surfaceHero: Color.alphaBlend(
        scheme.primary.withValues(
          alpha: isDark ? _surfaceHeroDark : _surfaceHeroLight,
        ),
        isDark ? scheme.surface : scheme.surfaceBright,
      ),
      // Composited over the runtime backdrop at paint time, never flattened.
      chromeGlass: scheme.surface.withValues(alpha: AppEffects.glassOpacity),
      ghostBorder: scheme.primary.withValues(
        alpha: isDark ? _ghostBorderDark : _ghostBorderLight,
      ),
    );
  }

  static const double _dangerSoftLight = 0.08;
  static const double _dangerSoftDark = 0.16;
  static const double _dangerBorderLight = 0.22;
  static const double _dangerBorderDark = 0.32;
  static const double _warningSoftLight = 0.12;
  static const double _warningSoftDark = 0.18;
  static const double _surfaceHeroLight = 0.05;
  static const double _surfaceHeroDark = 0.12;
  static const double _ghostBorderLight = 0.14;
  static const double _ghostBorderDark = 0.16;

  /// ErrorState tile tint.
  final Color dangerSoft;

  /// Destructive edge.
  final Color dangerBorder;

  /// Warning tint.
  final Color warningSoft;

  /// Tinted hero card fill.
  final Color surfaceHero;

  /// Bottom-nav glass surface.
  final Color chromeGlass;

  /// The 1px primary-tinted hairline on cards, chips, dividers and chrome.
  final Color ghostBorder;
}

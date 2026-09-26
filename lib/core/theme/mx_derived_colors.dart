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
    required this.warningBorder,
    required this.successSoft,
    required this.successBorder,
    required this.successInk,
    required this.surfaceHero,
    required this.chromeGlass,
    required this.ghostBorder,
    required this.warningInk,
    required this.statusNewInk,
    required this.statusLearningInk,
    required this.statusReviewingInk,
    required this.statusMasteredInk,
    required this.primaryInk,
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
      // The theme gap the InlineBanner contract reports: warning-border is
      // not in the derived registry. Its ratios come from that contract (O6).
      warningBorder: semantic.warning.withValues(
        alpha: isDark ? _warningBorderDark : _warningBorderLight,
      ),
      successSoft: semantic.success.withValues(
        alpha: isDark ? _successSoftDark : _successSoftLight,
      ),
      successBorder: semantic.success.withValues(
        alpha: isDark ? _successBorderDark : _successBorderLight,
      ),
      // Success TEXT and glyphs: the kit's green fails 4.5:1 on light
      // surfaces, so it is pulled toward onSurface as the status inks are.
      successInk: _ink(
        semantic.success,
        scheme,
        isDark ? _successInkDark : _successInkLight,
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
      // Kit-scoped (FieldMessage contract): the warning FILL fails as 12px
      // text on light surfaces, so light inks with onWarning and dark with
      // the amber itself.
      warningInk: isDark ? semantic.warning : semantic.onWarning,
      // Status TEXT (StatusBadge label, the workload "new" term): the
      // status colour pulled toward onSurface until it reads at 4.5:1 on
      // every ground and on its own 12% tint (library spec §7, ruling L6).
      // Dots, fills and tints keep the status colour itself.
      statusNewInk: _ink(
        semantic.statusNew,
        scheme,
        isDark ? _newInkDark : _newInkLight,
      ),
      statusLearningInk: _ink(
        semantic.statusLearning,
        scheme,
        isDark ? _learningInkDark : _learningInkLight,
      ),
      statusReviewingInk: _ink(
        semantic.statusReviewing,
        scheme,
        isDark ? _reviewingInkDark : _reviewingInkLight,
      ),
      statusMasteredInk: _ink(
        semantic.statusMastered,
        scheme,
        isDark ? _masteredInkDark : _masteredInkLight,
      ),
      primaryInk: primaryInkOf(scheme),
    );
  }

  static const double _dangerSoftLight = 0.08;
  static const double _dangerSoftDark = 0.16;
  static const double _dangerBorderLight = 0.22;
  static const double _dangerBorderDark = 0.32;
  static const double _warningSoftLight = 0.12;
  static const double _warningSoftDark = 0.18;
  static const double _warningBorderLight = 0.26;
  static const double _warningBorderDark = 0.32;
  static const double _successSoftLight = 0.10;
  static const double _successSoftDark = 0.18;
  static const double _successBorderLight = 0.26;
  static const double _successBorderDark = 0.32;
  static const double _successInkLight = 0.40;
  static const double _successInkDark = 0;
  static const double _surfaceHeroLight = 0.05;
  static const double _surfaceHeroDark = 0.12;
  static const double _ghostBorderLight = 0.14;
  static const double _ghostBorderDark = 0.16;
  static const double _newInkLight = 0.40;
  static const double _newInkDark = 0.40;
  static const double _learningInkLight = 0.50;
  static const double _learningInkDark = 0;
  static const double _reviewingInkLight = 0.25;
  static const double _reviewingInkDark = 0.10;
  static const double _masteredInkLight = 0.25;
  static const double _masteredInkDark = 0;
  static const double _primaryInkLight = 0.25;
  static const double _primaryInkDark = 0.45;

  /// Primary as TEXT, icon, focus ring or off-fill spinner: primary pulled
  /// toward onSurface until it reads at 4.5:1 on every ground and primary
  /// tint (spec 2026-09-27 D2). Fills, edges and tints keep primary. The
  /// one source for MxTextStyles and the component themes too.
  static Color primaryInkOf(ColorScheme scheme) => _ink(
    scheme.primary,
    scheme,
    scheme.brightness == Brightness.dark ? _primaryInkDark : _primaryInkLight,
  );

  static Color _ink(Color status, ColorScheme scheme, double mix) =>
      Color.lerp(status, scheme.onSurface, mix)!;

  /// ErrorState tile tint.
  final Color dangerSoft;

  /// Destructive edge.
  final Color dangerBorder;

  /// Warning tint.
  final Color warningSoft;

  /// InlineBanner warning edge.
  final Color warningBorder;

  /// Success tint (V3 success-soft).
  final Color successSoft;

  /// Success card edge, at the warning border's ratios.
  final Color successBorder;

  /// Success TEXT and glyphs, never the success fill.
  final Color successInk;

  /// Primary text, icons and focus rings, never a fill.
  final Color primaryInk;

  /// Tinted hero card fill.
  final Color surfaceHero;

  /// Bottom-nav glass surface.
  final Color chromeGlass;

  /// The 1px primary-tinted hairline on cards, chips, dividers and chrome.
  final Color ghostBorder;

  /// Warning TEXT (FieldMessage), never the warning fill.
  final Color warningInk;

  /// Status TEXT inks (StatusBadge label, WorkloadBreakdownLine new term),
  /// never the status dot or fill.
  final Color statusNewInk;
  final Color statusLearningInk;
  final Color statusReviewingInk;
  final Color statusMasteredInk;
}

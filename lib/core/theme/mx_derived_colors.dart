import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Phase 0 of the M3 colour-roles migration (spec 2026-10-08 §6, task 1):
/// the roles this layer derived from, frozen at their pre-migration values,
/// so a role's new value moves no consumer this layer still paints. The
/// layer and this record go in phase 5.
final class _FrozenRoles {
  const _FrozenRoles({
    required this.primary,
    required this.onSurface,
    required this.outline,
    required this.error,
    required this.surface,
    required this.surfaceBright,
    required this.warning,
    required this.success,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
  });

  static const light = _FrozenRoles(
    primary: Color(0xFF5265F5),
    onSurface: Color(0xFF0F1638),
    outline: Color(0xFF7C85AB),
    error: Color(0xFFC02447),
    surface: Color(0xFFF7F9FE),
    surfaceBright: Color(0xFFFFFFFF),
    warning: Color(0xFFF59E0B),
    success: Color(0xFF2BA88B),
    statusNew: Color(0xFF8C95B8),
    statusLearning: Color(0xFFF59E0B),
    statusReviewing: Color(0xFF5265F5),
    statusMastered: Color(0xFF1F8A5B),
  );

  static const dark = _FrozenRoles(
    primary: Color(0xFF5265F5),
    onSurface: Color(0xFFE4E8FA),
    outline: Color(0xFF5A6BAE),
    error: Color(0xFFFF8FA3),
    surface: Color(0xFF0A0E27),
    surfaceBright: Color(0xFF232B5A),
    warning: Color(0xFFFFC658),
    success: Color(0xFF6FE0BD),
    statusNew: Color(0xFF6B75A3),
    statusLearning: Color(0xFFFFC658),
    statusReviewing: Color(0xFF8B9AFF),
    statusMastered: Color(0xFF6FE0BD),
  );

  static _FrozenRoles of(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark ? dark : light;

  final Color primary;
  final Color onSurface;
  final Color outline;
  final Color error;
  final Color surface;
  final Color surfaceBright;
  final Color warning;
  final Color success;
  final Color statusNew;
  final Color statusLearning;
  final Color statusReviewing;
  final Color statusMastered;
}

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
    required this.ghostBorder,
    required this.warningInk,
    required this.dangerInk,
    required this.statusNewInk,
    required this.statusLearningInk,
    required this.statusReviewingInk,
    required this.statusMasteredInk,
    required this.primaryInk,
    required this.outlineEdge,
  });

  factory MxDerivedColors.resolve(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) {
    final roles = _FrozenRoles.of(scheme);
    final isDark = scheme.brightness == Brightness.dark;
    return MxDerivedColors._(
      dangerSoft: roles.error.withValues(
        alpha: isDark ? _dangerSoftDark : _dangerSoftLight,
      ),
      dangerBorder: roles.error.withValues(
        alpha: isDark ? _dangerBorderDark : _dangerBorderLight,
      ),
      warningSoft: roles.warning.withValues(
        alpha: isDark ? _warningSoftDark : _warningSoftLight,
      ),
      // The theme gap the InlineBanner contract reports: warning-border is
      // not in the derived registry. Its ratios come from that contract (O6).
      warningBorder: roles.warning.withValues(
        alpha: isDark ? _warningBorderDark : _warningBorderLight,
      ),
      successSoft: roles.success.withValues(
        alpha: isDark ? _successSoftDark : _successSoftLight,
      ),
      successBorder: roles.success.withValues(
        alpha: isDark ? _successBorderDark : _successBorderLight,
      ),
      // Success TEXT and glyphs: the kit's green fails 4.5:1 on light
      // surfaces, so it is pulled toward onSurface as the status inks are.
      successInk: _ink(
        roles.success,
        roles.onSurface,
        isDark ? _successInkDark : _successInkLight,
      ),
      // The one derivation whose base changes with the theme.
      surfaceHero: Color.alphaBlend(
        roles.primary.withValues(
          alpha: isDark ? _surfaceHeroDark : _surfaceHeroLight,
        ),
        isDark ? roles.surface : roles.surfaceBright,
      ),
      ghostBorder: roles.primary.withValues(
        alpha: isDark ? _ghostBorderDark : _ghostBorderLight,
      ),
      // Warning TEXT and glyphs. The amber fill fails as 12px text on light
      // surfaces, and onWarning (the ink on an amber fill) reads as body
      // text, so light uses the amber's hue at 28% lightness: 4.5:1 or more
      // on every ground and tint, the sheet included (critique 2026-09-30 tone pass, T1). Dark
      // inks with the amber itself.
      warningInk: isDark ? roles.warning : _warningInkLight,
      // Danger TEXT on the danger ground (a banner title). Error alone is
      // 4.20:1 (light) and 4.05:1 (dark) on that ground inside a sheet, so
      // it is pulled toward onSurface: 10% light, 30% dark, 4.5:1 or more on
      // every surface (critique 2026-09-30 tone pass, final review).
      dangerInk: _ink(
        roles.error,
        roles.onSurface,
        isDark ? _dangerInkDark : _dangerInkLight,
      ),
      // Status TEXT (StatusBadge label, the workload "new" term): the
      // status colour pulled toward onSurface until it reads at 4.5:1 on
      // every ground and on its own 12% tint (library spec §7, ruling L6).
      // Dots, fills and tints keep the status colour itself.
      statusNewInk: _ink(
        roles.statusNew,
        roles.onSurface,
        isDark ? _newInkDark : _newInkLight,
      ),
      statusLearningInk: _ink(
        roles.statusLearning,
        roles.onSurface,
        isDark ? _learningInkDark : _learningInkLight,
      ),
      statusReviewingInk: _ink(
        roles.statusReviewing,
        roles.onSurface,
        isDark ? _reviewingInkDark : _reviewingInkLight,
      ),
      statusMasteredInk: _ink(
        roles.statusMastered,
        roles.onSurface,
        isDark ? _masteredInkDark : _masteredInkLight,
      ),
      primaryInk: primaryInkOf(scheme),
      outlineEdge: outlineEdgeOf(scheme),
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
  // 18 %, not the kit's 12 %: the deeper #5265F5 needs it to lift the hero
  // off the page and its boxed tiles as the kit's #8B9AFF did (spec
  // 2026-09-27).
  static const double _surfaceHeroDark = 0.18;
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
  static const Color _warningInkLight = Color(0xFF895806);
  static const double _dangerInkLight = 0.10;
  static const double _dangerInkDark = 0.30;
  static const double _primaryInkLight = 0.25;
  static const double _primaryInkDark = 0.45;
  static const double _outlineEdgeSaturationLight = 0.30;
  static const double _outlineEdgeDark = 0.20;

  /// The one control edge: fields at rest, the outline button, the code
  /// slots. It holds 3:1 on the page, the field fill, the sheet and the
  /// warning ground in both themes, as lightly as it can (DEV-166, DEV-179):
  /// light keeps outline's hue and lightness and only raises its saturation;
  /// dark, where saturation alone cannot reach 3:1, pulls outline toward
  /// onSurface.
  static Color outlineEdgeOf(ColorScheme scheme) {
    final roles = _FrozenRoles.of(scheme);
    if (scheme.brightness == Brightness.dark) {
      return Color.lerp(roles.outline, roles.onSurface, _outlineEdgeDark)!;
    }
    return HSLColor.fromColor(roles.outline)
        .withSaturation(_outlineEdgeSaturationLight)
        .toColor();
  }

  /// Primary as TEXT, icon, focus ring or off-fill spinner: primary pulled
  /// toward onSurface until it reads at 4.5:1 on every ground and primary
  /// tint (spec 2026-09-27 D2). Fills, edges and tints keep primary. The
  /// one source for MxTextStyles and the component themes too.
  static Color primaryInkOf(ColorScheme scheme) {
    final roles = _FrozenRoles.of(scheme);
    return _ink(
      roles.primary,
      roles.onSurface,
      scheme.brightness == Brightness.dark ? _primaryInkDark : _primaryInkLight,
    );
  }

  static Color _ink(Color status, Color onSurface, double mix) =>
      Color.lerp(status, onSurface, mix)!;

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

  /// The 1px primary-tinted hairline on cards, chips, dividers and chrome.
  final Color ghostBorder;

  /// The outline button's 1px edge (see [MxDerivedColors.resolve]).
  final Color outlineEdge;

  /// Warning TEXT (FieldMessage), never the warning fill.
  final Color warningInk;

  /// Danger TEXT on the danger ground (an MxInlineBanner title); glyphs and
  /// fills keep error.
  final Color dangerInk;

  /// Status TEXT inks (StatusBadge label, WorkloadBreakdownLine new term),
  /// never the status dot or fill.
  final Color statusNewInk;
  final Color statusLearningInk;
  final Color statusReviewingInk;
  final Color statusMasteredInk;
}

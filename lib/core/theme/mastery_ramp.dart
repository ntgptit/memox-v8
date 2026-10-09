import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// The single-colour mastery ramp (V3 MasteryRamp utility). One threshold
/// function feeds every mastery fill, so a 40% deck is the same colour on
/// every screen. It paints nothing itself.
abstract final class MasteryRamp {
  /// First fraction painted as reviewing (34%).
  static const double _reviewingFrom = 0.34;

  /// First fraction painted as mastered (67%).
  static const double _masteredFrom = 0.67;

  static void _check(double fraction) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
  }

  /// The flat fill for [fraction] in `[0, 1]`, or null at 0, where only the
  /// track is painted. Never a gradient. Learning is the warning role (tone
  /// 40 / 80, 5.90 / 9.01 on the track), reviewing the brand fill (4.20 /
  /// 3.31), mastered the mastery role (spec 2026-10-08 §4.7).
  static Color? fill(
    MxSemanticColors semantic,
    ColorScheme scheme,
    double fraction,
  ) {
    _check(fraction);
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return semantic.warning;
    if (fraction < _masteredFrom) return scheme.primary;
    return semantic.mastery;
  }

  /// The band's foreground for text beside or inside the fill, such as the
  /// donut's percentage: the role itself, except reviewing, whose fill is
  /// the brand and whose text is primaryForeground (The Role Pair Rule).
  /// 0 reads in the lowest band.
  static Color foreground(
    MxSemanticColors semantic,
    ColorScheme scheme,
    double fraction,
  ) {
    _check(fraction);
    if (fraction < _reviewingFrom) return semantic.warning;
    if (fraction < _masteredFrom) return semantic.primaryForeground;
    return semantic.mastery;
  }

  /// [fraction] as a whole percent that never rounds to a lie: 0 only at 0,
  /// 100 only at 1, and 1…99 between (deck mastery spec D13).
  static int percent(double fraction) {
    _check(fraction);
    if (fraction == 0) return 0;
    if (fraction == 1) return 100;
    return (fraction * 100).round().clamp(1, 99);
  }

  /// The unfilled track: surfaceContainerLow, so the primary fill keeps 3:1
  /// against it in dark too (FE-C1).
  static Color track(ColorScheme scheme) => scheme.surfaceContainerLow;
}

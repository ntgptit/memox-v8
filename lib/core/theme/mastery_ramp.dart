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

  /// The flat fill for [fraction] in `[0, 1]`, or null at 0, where only the
  /// track is painted. Never a gradient.
  static Color? fill(MxSemanticColors semantic, double fraction) {
    _check(fraction);
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return semantic.statusLearning;
    if (fraction < _masteredFrom) return semantic.statusReviewing;
    return semantic.statusMastered;
  }

  /// The text token of [fraction]'s band, for a percentage beside or inside
  /// the fill. 0 reads in the lowest band.
  static Color label(MxSemanticColors semantic, double fraction) {
    _check(fraction);
    if (fraction < _reviewingFrom) return semantic.learningText;
    if (fraction < _masteredFrom) return semantic.primaryText;
    return semantic.masteryText;
  }

  /// [fraction] as a whole percent that never rounds to a lie: 0 only at 0,
  /// 100 only at 1, and 1…99 between (deck mastery spec D13).
  static int percent(double fraction) {
    _check(fraction);
    if (fraction == 0) return 0;
    if (fraction == 1) return 100;
    return (fraction * 100).round().clamp(1, 99);
  }

  static void _check(double fraction) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
  }

  /// The unfilled track: surfaceContainerLow.
  static Color track(ColorScheme scheme) => scheme.surfaceContainerLow;
}

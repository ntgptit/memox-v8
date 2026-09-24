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
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return semantic.statusLearning;
    if (fraction < _masteredFrom) return semantic.statusReviewing;
    return semantic.statusMastered;
  }

  /// The unfilled track (progress-track = surfaceContainerHigh).
  static Color track(ColorScheme scheme) => scheme.surfaceContainerHigh;
}

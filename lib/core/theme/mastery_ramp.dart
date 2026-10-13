import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';

/// The single-colour mastery ramp. One threshold function feeds every mastery
/// fill, so a 40% deck is the same colour on every screen. It paints nothing
/// itself.
abstract final class MasteryRamp {
  /// First fraction painted as reviewing (34%).
  static const double _reviewingFrom = 0.34;

  /// First fraction painted as mastered (67%).
  static const double _masteredFrom = 0.67;

  /// The flat fill for [fraction] in `[0, 1]`, or null at 0, where only the
  /// track is painted. Never a gradient. [accent] is the context's accent
  /// colour for the reviewing band.
  static Color? fill(MxColorsExtension mx, Color accent, double fraction) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return mx.warning;
    if (fraction < _masteredFrom) return accent;
    return mx.successContainer;
  }

  /// [fraction] as a whole percent that never rounds to a lie: 0 only at 0,
  /// 100 only at 1, and 1…99 between (deck mastery spec D13).
  static int percent(double fraction) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
    if (fraction == 0) return 0;
    if (fraction == 1) return 100;
    return (fraction * 100).round().clamp(1, 99);
  }

  /// The unfilled track.
  static Color track(ColorScheme scheme) => scheme.surfaceContainerHighest;
}

import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
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
  /// track is painted. Never a gradient. The learning band is the learning
  /// ink: the kit's amber is 1.73:1 on the track in light (deck mastery
  /// spec R4); in dark the ink is the amber itself.
  static Color? fill(
    MxSemanticColors semantic,
    MxDerivedColors derived,
    double fraction,
  ) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return derived.statusLearningInk;
    if (fraction < _masteredFrom) return semantic.statusReviewing;
    return semantic.statusMastered;
  }

  /// The status ink of [fraction]'s band, for text such as a percentage
  /// beside or inside the fill: the fill colours fail 4.5:1 as text (The Ink
  /// Is Not The Fill Rule, SW-REV-001). 0 reads in the lowest band.
  static Color ink(
    MxSemanticColors semantic,
    MxDerivedColors derived,
    double fraction,
  ) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
    if (fraction < _reviewingFrom) return derived.statusLearningInk;
    if (fraction < _masteredFrom) return derived.statusReviewingInk;
    return derived.statusMasteredInk;
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

  /// The unfilled track: surfaceContainerLow, so the primary fill keeps 3:1
  /// against it in dark too (FE-C1; the kit's surfaceContainerHigh gave 2.46).
  static Color track(ColorScheme scheme) => scheme.surfaceContainerLow;
}

import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

/// The single-colour mastery ramp. One threshold function feeds every mastery
/// fill, so a 40% deck is the same colour on every screen. It paints nothing
/// itself.
abstract final class MasteryRamp {
  /// First fraction painted as reviewing (34%).
  static const double _reviewingFrom = 0.34;

  /// First fraction painted as mastered (67%).
  static const double _masteredFrom = 0.67;

  /// The flat fill for [fraction] in `[0, 1]`, or null at 0, where only the
  /// track is painted. Never a gradient. The reviewing band is the accent
  /// fill, which holds 3:1 on every ground (follow-ups spec G9).
  static Color? fill(MxStatusColors status, double fraction) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return status.warningFill;
    if (fraction < _masteredFrom) return status.accentFill;
    return status.successFill;
  }

  /// The text colour of [fraction]'s band, for a percentage beside or inside
  /// the fill: the fill colours are not text colours (SW-REV-001). 0 reads in
  /// the lowest band.
  static Color foreground(
    MxStatusColors status,
    Color accent,
    double fraction,
  ) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
    if (fraction < _reviewingFrom) return status.warning;
    if (fraction < _masteredFrom) return accent;
    return status.success;
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

  /// The unfilled track, as ForUI's progress track.
  static Color track(FColors colors) => colors.muted;
}

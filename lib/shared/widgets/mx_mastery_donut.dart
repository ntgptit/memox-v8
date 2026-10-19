import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_donut.dart';

/// The circular mastery indicator. The ring fills clockwise from twelve
/// o'clock in the MasteryRamp colour, and the percentage uses the same
/// colour, so the number and the ring never disagree.
class MxMasteryDonut extends StatelessWidget {
  const MxMasteryDonut({super.key, required this.fraction, this.semanticLabel})
    : assert(fraction >= 0 && fraction <= 1, 'fraction is within [0, 1]');

  final double fraction;

  /// What the percentage measures ("Mastered"), read before it (§9 row 61).
  /// Null reads the percentage alone.
  final String? semanticLabel;

  static const double _box = 56;

  /// The kit's geometry: r 17 and stroke 3 on a 40 viewBox, scaled to the
  /// box.
  static const double _viewBox = 40;
  static const double _viewRadius = 17;
  static const double _viewStroke = 3;
  static const double _scale = _box / _viewBox;

  /// The clear space inside the stroke, where the label scales down to fit
  /// (ruling S10).
  static const double _innerDiameter = (_viewRadius * 2 - _viewStroke) * _scale;

  @override
  Widget build(BuildContext context) {
    // The arc is the ramp's fill; the label is text, so it takes the band's
    // text colour (SW-REV-001). Ruling S10: 0% falls in the lowest band.
    final status = context.status;
    final accent = context.colors.primary;
    final fill = MasteryRamp.fill(status, fraction) ?? status.warningFill;
    final foreground = MasteryRamp.foreground(status, accent, fraction);
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    ).format(MasteryRamp.percent(fraction) / 100);
    final donut = SizedBox.square(
      dimension: _box,
      child: MxDonut(
        fraction: fraction,
        arc: fill,
        // The ramp's progress track, the same as the mastery bar's.
        track: MasteryRamp.track(context.colors),
        strokeWidth: _viewStroke * _scale,
        radius: _viewRadius * _scale,
        child: SizedBox.square(
          dimension: _innerDiameter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              percent,
              style: context.texts.meta.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return donut;
    return Semantics(
      label: label,
      value: percent,
      excludeSemantics: true,
      child: donut,
    );
  }
}

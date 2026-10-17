import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

// WCAG 2 contrast of the palette's pairs (ADR-026): text keeps 4.5:1 and a
// glyph or control edge 3:1, in both modes, on the grounds the widgets draw
// them on. No exception is recorded: a pair below its floor is a palette
// change in lib/core/theme/app_palette.dart.

const double _text = 4.5;
const double _nonText = 3;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// [ink] laid over [ground] when [ink] is translucent.
Color _over(Color ink, Color ground) => Color.alphaBlend(ink, ground);

typedef _Pair = (String name, Color ink, Color ground, double minimum);

List<_Pair> _pairs(FColors colors) {
  final status = colors.extension<MxStatusColors>();
  final pairs = <_Pair>[];
  void add(String name, Color ink, Color ground, [double min = _text]) =>
      pairs.add((name, ink, _over(ground, colors.background), min));

  for (final (where, ground) in [
    ('background', colors.background),
    ('card', colors.card),
    ('muted', colors.muted),
  ]) {
    add('foreground on $where', colors.foreground, ground);
    add('mutedForeground on $where', colors.mutedForeground, ground);
    add('primary on $where', colors.primary, ground);
    add('error on $where', colors.error, ground);
    add('success on $where', status.success, ground);
    add('warning on $where', status.warning, ground);
    add('info on $where', status.info, ground);
  }
  for (final (where, ground) in [
    ('background', colors.background),
    ('card', colors.card),
  ]) {
    // A tint carries its own ink: a banner, a badge, an answered choice.
    for (final (role, ink) in [
      ('primary', colors.primary),
      ('error', colors.error),
      ('success', status.success),
      ('warning', status.warning),
    ]) {
      add('$role on its tint over $where', ink, ink.tintOver(ground));
    }
  }
  add('primaryForeground on primary', colors.primaryForeground, colors.primary);
  add('errorForeground on error', colors.errorForeground, colors.error);
  add(
    'secondaryForeground on secondary',
    colors.secondaryForeground,
    colors.secondary,
  );
  add('onSuccessFill on successFill', status.onSuccessFill, status.successFill);
  add('onWarningFill on warningFill', status.onWarningFill, status.warningFill);
  // A control's resting edge or a supporting glyph.
  add(
    'mutedForeground glyph on background',
    colors.mutedForeground,
    colors.background,
    _nonText,
  );
  return pairs;
}

void main() {
  for (final (mode, colors) in [
    ('light', appLightColors),
    ('dark', appDarkColors),
  ]) {
    group(mode, () {
      for (final (name, ink, ground, minimum) in _pairs(colors)) {
        test(name, () {
          final ratio = _contrast(_over(ink, ground), ground);
          expect(
            ratio,
            greaterThanOrEqualTo(minimum),
            reason: '$name is ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    });
  }
}

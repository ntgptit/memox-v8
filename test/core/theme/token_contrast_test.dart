import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

import '../../support/contrast.dart';

// WCAG 2 contrast of the palette's pairs (ADR-026): text keeps 4.5:1 and a
// glyph or control edge 3:1, in both modes, on the grounds the widgets draw
// them on. A pair below its floor is a palette change in
// lib/core/theme/app_palette.dart, except the pairs in [_darkExceptions].

const double _text = 4.5;
const double _nonText = 3;

/// [ink] laid over [ground] when [ink] is translucent.
Color _over(Color ink, Color ground) => Color.alphaBlend(ink, ground);

typedef _Pair = (String name, Color ink, Color ground, double minimum);

/// Owner ruling 2026-10-17: dark mode keeps the brand indigo on the MemoX
/// navy page as before the ForUI migration, so dark primary as text sits
/// below 4.5:1. Each pair is held at the ratio it has under that ruling, so
/// a further drop still fails.
const Map<String, double> _darkExceptions = {
  'primary on background': 3.0,
  'primary on card': 2.71,
  'primary on muted': 2.33,
};

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
    // The accent tint's label is the accent mark (owner ruling 2026-10-17).
    add(
      'accentMark on the primary tint over $where',
      status.accentMark,
      colors.primary.tintOver(ground),
    );
    for (final (role, ink) in [
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
  // An accent mark as a glyph: an icon tile's glyph, a dot, the selected
  // tab's icon.
  for (final (where, ground) in [
    ('background', colors.background),
    ('card', colors.card),
    ('muted', colors.muted),
  ]) {
    add('accentMark glyph on $where', status.accentMark, ground, _nonText);
    // The accent as a data fill: a bar, a band, a line, a track
    // (follow-ups spec G9).
    add('accentFill on $where', status.accentFill, ground, _nonText);
  }
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
      for (final (name, ink, ground, floor) in _pairs(colors)) {
        final minimum = mode == 'dark' ? _darkExceptions[name] ?? floor : floor;
        test(name, () {
          final ratio = contrastRatio(_over(ink, ground), ground);
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

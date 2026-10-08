import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// FE-C1: the palette's ink and edge pairs meet WCAG 2.2 AA, worked from the
// tokens rather than sampled from pixels: Flutter's textContrastGuideline
// misreads anti-aliased 12px text and filled buttons, so it stays out of
// the screen audit. A tint is its alpha laid over the ground it sits on.

const double _text = 4.5;
const double _nonText = 3;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Color _tint(Color color, double alpha, Color ground) =>
    Color.alphaBlend(color.withValues(alpha: alpha), ground);

typedef _Pair = (String name, Color ink, Color ground, double minimum);

List<_Pair> _pairs(ColorScheme scheme, MxSemanticColors semantic) {
  final derived = MxDerivedColors.resolve(scheme, semantic);
  final page = scheme.surface;
  final sheet = scheme.surfaceContainerHigh;
  final row = scheme.surfaceContainerLowest;
  final track = MasteryRamp.track(scheme);
  return [
    for (final (ground, where) in [
      (page, 'page'),
      (row, 'row'),
      (scheme.surfaceContainerLow, 'low'),
      (sheet, 'sheet'),
    ]) ...[
      ('error text on $where', scheme.error, ground, _text),
      ('primaryInk on $where', derived.primaryInk, ground, _text),
      ('variant text on $where', scheme.onSurfaceVariant, ground, _text),
      ('newInk on $where', derived.statusNewInk, ground, _text),
      ('learningInk on $where', derived.statusLearningInk, ground, _text),
      ('masteredInk on $where', derived.statusMasteredInk, ground, _text),
    ],
    // The Progress day bars on their card, the container-lowest ground
    // (critique 2026-10-02, F5); learning's ink is held at 4.5 above.
    ('reviewing bars on the card', scheme.primary, row, _nonText),
    ('snackbar action', scheme.inversePrimary, scheme.inverseSurface, _text),
    (
      'danger badge on its 12% tint',
      scheme.error,
      _tint(scheme.error, 0.12, page),
      _text,
    ),
    (
      'mastery badge ink on its 12% tint',
      derived.statusMasteredInk,
      _tint(semantic.mastery, 0.12, page),
      _text,
    ),
    (
      'warning banner text',
      derived.warningInk,
      Color.alphaBlend(derived.warningSoft, page),
      _text,
    ),
    (
      'warning banner glyph',
      derived.warningInk,
      Color.alphaBlend(derived.warningSoft, page),
      _nonText,
    ),
    // The off toggle's edge, the unselected radio and the unchecked box are
    // control edges too: they take Outline Edge, held on every ground by the
    // loop at the end (shared widgets review 2026-10-07, SW-REV-001).
    // The donut's 9px label is text: the ramp's ink, never its fill, on the
    // hero card it sits on.
    for (final fraction in [0.2, 0.5, 0.9])
      (
        'donut label at $fraction on the hero',
        MasteryRamp.ink(semantic, derived, fraction),
        derived.surfaceHero,
        _text,
      ),
    ('selected filter chip count', scheme.onPrimary, scheme.primary, _text),
    (
      'toggle off thumb on its track',
      scheme.onSurfaceVariant,
      scheme.surfaceContainerHighest,
      _nonText,
    ),
    ('progress fill on its track', scheme.primary, track, _nonText),
    ('sheet grabber', scheme.onSurfaceVariant, sheet, _nonText),
    // Critique 2026-09-30: a Guess option out of play fades as a whole (ink and
    // surface) to AppOpacity.muted over the page, and must stay readable.
    (
      'faded choice ink',
      _tint(scheme.onSurface, AppOpacity.muted, page),
      _tint(scheme.surfaceContainerLowest, AppOpacity.muted, page),
      _text,
    ),
    // The one control edge (DEV-166, spec 2026-10-05 control edges §3.1):
    // fields, outline buttons and code slots hold 3:1 on the grounds they
    // sit on (page, field fill, card, sheet, warning), in both themes.
    for (final (ground, where) in [
      (page, 'page'),
      (scheme.surfaceContainerLow, 'field fill'),
      (scheme.surfaceContainerLowest, 'lowest'),
      (sheet, 'sheet'),
      (Color.alphaBlend(derived.warningSoft, page), 'warning ground'),
    ])
      ('outline edge on $where', derived.outlineEdge, ground, _nonText),
  ];
}

void main() {
  for (final (theme, scheme, semantic) in [
    ('light', AppColorSchemes.light, MxSemanticColors.light),
    ('dark', AppColorSchemes.dark, MxSemanticColors.dark),
  ]) {
    group('$theme palette meets WCAG 2.2 AA', () {
      for (final (name, ink, ground, minimum) in _pairs(scheme, semantic)) {
        test(name, () {
          expect(
            _contrast(ink, ground),
            greaterThanOrEqualTo(minimum),
            reason:
                '#${ink.toARGB32().toRadixString(16)} on '
                '#${ground.toARGB32().toRadixString(16)}',
          );
        });
      }
    });
  }
}

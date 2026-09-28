import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    ('toggle off edge on a row', scheme.outline, row, _nonText),
    (
      'toggle off thumb on its track',
      scheme.onSurfaceVariant,
      scheme.surfaceContainerHighest,
      _nonText,
    ),
    ('progress fill on its track', scheme.primary, track, _nonText),
    ('sheet grabber', scheme.onSurfaceVariant, sheet, _nonText),
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

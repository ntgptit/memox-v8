import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
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

// Spec 2026-10-08 §4.3 / §4.8: every foreground / ground pair the app paints,
// by role. The table is the oracle: a new pair is added here first.

Color _layer(Color over, Color ground) =>
    Color.alphaBlend(over.withValues(alpha: AppOpacity.pressed), ground);

typedef _Pair = (String name, Color ink, Color ground, double minimum);

List<_Pair> _pairs(ColorScheme scheme, MxSemanticColors semantic) {
  final sheet = scheme.surfaceContainerHigh;
  final hero = scheme.surfaceContainerLow;
  final track = MasteryRamp.track(scheme);
  final grounds = [
    (scheme.surface, 'page'),
    (scheme.surfaceContainerLowest, 'card'),
    (scheme.surfaceContainerLow, 'low'),
    (scheme.surfaceContainer, 'container'),
    (sheet, 'sheet'),
  ];
  final containers = [
    (scheme.primaryContainer, 'primary container'),
    (scheme.errorContainer, 'error container'),
    (semantic.warningContainer, 'warning container'),
    (semantic.successContainer, 'success container'),
    (semantic.masteryContainer, 'mastery container'),
  ];
  return [
    for (final (ground, where) in grounds) ...[
      (
        'primaryForeground on $where',
        semantic.primaryForeground,
        ground,
        _text,
      ),
      ('warning on $where', semantic.warning, ground, _text),
      ('success on $where', semantic.success, ground, _text),
      ('mastery on $where', semantic.mastery, ground, _text),
      ('streak on $where', semantic.streak, ground, _text),
      ('error on $where', scheme.error, ground, _text),
      ('onSurface on $where', scheme.onSurface, ground, _text),
      ('onSurfaceVariant on $where', scheme.onSurfaceVariant, ground, _text),
      ('outline edge on $where', scheme.outline, ground, _nonText),
    ],
    // Text and glyphs on a container: its on-container, or the role.
    for (final (ground, where) in containers)
      (
        'primaryForeground ring on $where',
        semantic.primaryForeground,
        ground,
        _text,
      ),
    (
      'onPrimaryContainer on its container',
      scheme.onPrimaryContainer,
      scheme.primaryContainer,
      _text,
    ),
    (
      'onSurfaceVariant on the primary container',
      scheme.onSurfaceVariant,
      scheme.primaryContainer,
      _text,
    ),
    (
      'outline on the primary container',
      scheme.outline,
      scheme.primaryContainer,
      _nonText,
    ),
    (
      'onErrorContainer on its container',
      scheme.onErrorContainer,
      scheme.errorContainer,
      _text,
    ),
    (
      'error glyph on its container',
      scheme.error,
      scheme.errorContainer,
      _text,
    ),
    (
      'onWarningContainer on its container',
      semantic.onWarningContainer,
      semantic.warningContainer,
      _text,
    ),
    (
      'warning glyph on its container',
      semantic.warning,
      semantic.warningContainer,
      _text,
    ),
    (
      'onSuccessContainer on its container',
      semantic.onSuccessContainer,
      semantic.successContainer,
      _text,
    ),
    (
      'success glyph on its container',
      semantic.success,
      semantic.successContainer,
      _text,
    ),
    (
      'onMasteryContainer on its container',
      semantic.onMasteryContainer,
      semantic.masteryContainer,
      _text,
    ),
    (
      'mastery glyph on its container',
      semantic.mastery,
      semantic.masteryContainer,
      _text,
    ),
    (
      'warning on the primary container',
      semantic.warning,
      scheme.primaryContainer,
      _text,
    ),
    (
      'mastery on the primary container',
      semantic.mastery,
      scheme.primaryContainer,
      _text,
    ),
    // On-colours on their fills.
    ('onPrimary on primary', scheme.onPrimary, scheme.primary, _text),
    ('onError on error', scheme.onError, scheme.error, _text),
    ('onWarning on warning', semantic.onWarning, semantic.warning, _text),
    ('onSuccess on success', semantic.onSuccess, semantic.success, _text),
    ('onMastery on mastery', semantic.onMastery, semantic.mastery, _text),
    // The brand fill where it identifies something (R7): the page, the card,
    // the hero and the progress track. Not the sheet (R17 covers that).
    ('primary fill on the page', scheme.primary, scheme.surface, _nonText),
    (
      'primary fill on the card',
      scheme.primary,
      scheme.surfaceContainerLowest,
      _nonText,
    ),
    ('primary fill on the hero', scheme.primary, hero, _nonText),
    ('progress fill on its track', scheme.primary, track, _nonText),
    ('learning fill on its track', semantic.warning, track, _nonText),
    ('mastered fill on its track', semantic.mastery, track, _nonText),
    // The donut label is text in its band's foreground, on the hero.
    for (final fraction in [0.0, 0.2, 0.5, 0.9, 1.0])
      (
        'donut label at $fraction on the hero',
        MasteryRamp.foreground(semantic, scheme, fraction),
        hero,
        _text,
      ),
    // Pressed state layers (spec §4.13 round 2): shadow over a filled tone.
    (
      'pressed primary label',
      scheme.onPrimary,
      _layer(scheme.shadow, scheme.primary),
      _text,
    ),
    (
      'pressed destructive label',
      scheme.onError,
      _layer(scheme.shadow, scheme.error),
      _text,
    ),
    (
      'pressed warning label',
      semantic.onWarning,
      _layer(scheme.shadow, semantic.warning),
      _text,
    ),
    // Toggle and checkbox marks (R17: the on-colour mark carries the state).
    ('toggle on thumb', scheme.onPrimary, scheme.primary, _nonText),
    (
      'toggle off thumb on its track',
      scheme.onSurfaceVariant,
      scheme.surfaceContainerHighest,
      _nonText,
    ),
    ('checked box mark', scheme.onPrimary, scheme.primary, _nonText),
    ('unchecked box edge on the sheet', scheme.outline, sheet, _nonText),
    // Chrome that did not move.
    ('snackbar action', scheme.inversePrimary, scheme.inverseSurface, _text),
    ('sheet grabber', scheme.onSurfaceVariant, sheet, _nonText),
    (
      'faded choice ink',
      Color.alphaBlend(
        scheme.onSurface.withValues(alpha: AppOpacity.muted),
        scheme.surface,
      ),
      Color.alphaBlend(
        scheme.surfaceContainerLowest.withValues(alpha: AppOpacity.muted),
        scheme.surface,
      ),
      _text,
    ),
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

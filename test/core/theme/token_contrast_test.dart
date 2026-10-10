import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// The palette's text and edge pairs, worked from the tokens (Flutter's
// textContrastGuideline misreads anti-aliased 12px text). A pair at its
// WCAG 2.2 AA floor is asserted at that floor. The palette is fixed (owner
// 2026-10-10, spec D3), so a pair below it is a named exception asserted
// at its measured floor: a palette edit that worsens it, or a new pair that
// fails, turns this red, and an exception that comes to pass must move out.

const double _text = 4.5;
const double _nonText = 3;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Color _tint(Color color, double alpha, Color ground) =>
    Color.alphaBlend(color.withValues(alpha: alpha), ground);

typedef _Pair = (String name, Color fore, Color ground, double minimum);

/// The measured floors of the pairs below AA (owner 2026-10-10, spec D3).
const _exceptions = <String, double>{
  'day/warningText on page': 4.20,
  'day/warningText on row': 4.20,
  'day/warningText on low': 3.92,
  'day/learningText on low': 4.20,
  'day/outline on page': 2.76,
  'day/outline on row': 2.76,
  'day/outline on low': 2.58,
  'day/focusRing on page': 2.01,
  'day/focusRing on row': 2.01,
  'day/focusRing on low': 1.88,
  'day/learning fill on its track': 1.99,
  'day/learning bars on the card': 2.13,
  'day/onMastery on mastery': 2.84,
  'day/mastered fill on its track': 2.65,
  'day/toggle off thumb on its track': 2.76,
  'day/learning label on the hero': 3.94,
  'day/mastered label on the hero': 4.25,
  'day/onLearningSoft on learningSoft': 4.22,
  'day/onWarningSoft on warningSoft': 3.59,
  'day/outline on the warning ground': 2.36,
  'night/error on row': 4.43,
  'night/error on low': 3.27,
  'night/primaryText on low': 3.54,
  'night/outline on row': 2.61,
  'night/outline on low': 1.92,
  'night/reviewing bars on the card': 2.95,
  'night/progress fill on its track': 2.18,
  'night/toggle off thumb on its track': 2.76,
  'night/onMastery on mastery': 2.84,
  'night/onLearningSoft on learningSoft': 4.22,
  'night/onWarningSoft on warningSoft': 3.59,
  'night/outline on the warning ground': 2.36,
};

List<_Pair> _pairs(
  ColorScheme scheme,
  MxSemanticColors semantic,
  ColorScheme day,
) {
  final page = scheme.surface;
  final row = scheme.surfaceContainerLowest;
  final low = scheme.surfaceContainerLow;
  return [
    for (final (ground, where) in [
      (page, 'page'),
      (row, 'row'),
      (low, 'low'),
    ]) ...[
      ('onSurface on $where', scheme.onSurface, ground, _text),
      ('onSurfaceVariant on $where', scheme.onSurfaceVariant, ground, _text),
      ('error on $where', scheme.error, ground, _text),
      ('primaryText on $where', semantic.primaryText, ground, _text),
      ('masteryText on $where', semantic.masteryText, ground, _text),
      ('learningText on $where', semantic.learningText, ground, _text),
      ('warningText on $where', semantic.warningText, ground, _text),
      ('success on $where', semantic.success, ground, _text),
      ('outline on $where', scheme.outline, ground, _nonText),
      ('focusRing on $where', semantic.focusRing, ground, _nonText),
    ],
    ('reviewing bars on the card', semantic.statusReviewing, row, _nonText),
    ('learning bars on the card', semantic.statusLearning, row, _nonText),
    ('progress fill on its track', scheme.primary, low, _nonText),
    ('learning fill on its track', semantic.statusLearning, low, _nonText),
    ('mastered fill on its track', semantic.statusMastered, low, _nonText),
    ('snackbar message', scheme.onInverseSurface, scheme.inverseSurface, _text),
    ('snackbar action', scheme.inversePrimary, scheme.inverseSurface, _text),
    ('onPrimary on primary', scheme.onPrimary, scheme.primary, _text),
    ('onWarning on warning', semantic.onWarning, semantic.warning, _text),
    // A done import step's glyph on its fill.
    ('onMastery on mastery', semantic.onMastery, semantic.mastery, _nonText),
    (
      'onErrorFill on errorFill',
      semantic.onErrorFill,
      semantic.errorFill,
      _text,
    ),
    (
      'toggle off thumb on its track',
      scheme.onPrimary,
      semantic.neutralTrack,
      _nonText,
    ),
    (
      'toggle on thumb on its track',
      scheme.primary,
      semantic.primaryTrack,
      _nonText,
    ),
    ('sheet grabber', scheme.onSurfaceVariant, row, _nonText),
    // The donut's 9px label sits on the hero card.
    (
      'learning label on the hero',
      semantic.learningText,
      scheme.primaryContainer,
      _text,
    ),
    (
      'reviewing label on the hero',
      semantic.primaryText,
      scheme.primaryContainer,
      _text,
    ),
    (
      'mastered label on the hero',
      semantic.masteryText,
      scheme.primaryContainer,
      _text,
    ),
    // Soft grounds are light in both themes (D4).
    (
      'onPrimarySoft on primarySoft',
      semantic.onPrimarySoft,
      semantic.primarySoft,
      _text,
    ),
    (
      'onSuccessSoft on successSoft',
      semantic.onSuccessSoft,
      semantic.successSoft,
      _text,
    ),
    (
      'onLearningSoft on learningSoft',
      semantic.onLearningSoft,
      semantic.learningSoft,
      _text,
    ),
    (
      'onWarningSoft on warningSoft',
      semantic.onWarningSoft,
      semantic.warningSoft,
      _text,
    ),
    (
      'onDangerSoft on dangerSoft',
      semantic.onDangerSoft,
      semantic.dangerSoft,
      _text,
    ),
    (
      'onNeutralSoft on neutralSoft',
      semantic.onNeutralSoft,
      semantic.neutralSoft,
      _text,
    ),
    ('onSoft on warningSoft', semantic.onSoft, semantic.warningSoft, _text),
    ('onSoft on dangerSoft', semantic.onSoft, semantic.dangerSoft, _text),
    ('onSoft on successSoft', semantic.onSoft, semantic.successSoft, _text),
    // A soft ground renders its content in Day (R1), so an outline button
    // inside a warning card carries Day's outline in both themes.
    (
      'outline on the warning ground',
      day.outline,
      semantic.warningSoft,
      _nonText,
    ),
    // A Guess option out of play fades as a whole to AppOpacity.muted.
    (
      'faded choice text',
      _tint(scheme.onSurface, AppOpacity.muted, page),
      _tint(row, AppOpacity.muted, page),
      _text,
    ),
  ];
}

const _themes = [
  ('day', MxSemanticColors.light),
  ('night', MxSemanticColors.dark),
];

ColorScheme _scheme(String theme) =>
    theme == 'day' ? AppColorSchemes.light : AppColorSchemes.dark;

void main() {
  for (final (theme, semantic) in _themes) {
    group('$theme palette contrast', () {
      final pairs = _pairs(_scheme(theme), semantic, AppColorSchemes.light);
      for (final (name, fore, ground, minimum) in pairs) {
        final ratio = _contrast(fore, ground);
        final reason =
            '#${fore.toARGB32().toRadixString(16)} on '
            '#${ground.toARGB32().toRadixString(16)}';
        final floor = _exceptions['$theme/$name'];
        if (floor == null) {
          test(name, () {
            expect(ratio, greaterThanOrEqualTo(minimum), reason: reason);
          });
          continue;
        }
        test('$name (exception)', () {
          expect(ratio, greaterThanOrEqualTo(floor), reason: reason);
          expect(ratio, lessThan(minimum), reason: '$reason now passes');
        });
      }
    });
  }

  test('every exception names a checked pair', () {
    final names = {
      for (final (theme, semantic) in _themes)
        for (final pair in _pairs(
          _scheme(theme),
          semantic,
          AppColorSchemes.light,
        ))
          '$theme/${pair.$1}',
    };
    expect(names.containsAll(_exceptions.keys), isTrue);
  });
}

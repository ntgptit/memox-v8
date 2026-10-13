import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// The palette's text and edge pairs, worked from the tokens (Flutter's
// textContrastGuideline misreads anti-aliased 12px text). A pair at its
// WCAG 2.2 AA floor is asserted at that floor. The palette is fixed
// ("Flashcard Color Tokens" §2.3, owner 2026-10-13, ADR-022), so a pair
// below it is a named exception asserted at its measured ratio: a palette
// edit that worsens it, or a new pair that fails, turns this red, and an
// exception that comes to pass must move out.

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

/// The measured ratios of the pairs below AA, each floored to two places
/// (spec §2.3: the owner accepted them with the palette).
const _exceptions = <String, double>{
  // Status fills and glyphs on the light card and track: the warning and
  // success containers are mid-tone fills, never text (spec §2.1).
  'light/learning bars on the card': 1.91,
  'light/mastered bars on the card': 2.54,
  'light/progress fill on its track': 2.32,
  'light/learning fill on its track': 1.75,
  'light/mastered fill on its track': 2.32,
  'light/streak glyph on its tile': 1.68,
  // The focus ring is primary in both themes (spec §6).
  'dark/focusRing on card': 2.38,
  'dark/focusRing on low': 2.77,
  // The accent fill on the dark hero ground: the button's label carries it
  // (onPrimary on primary passes).
  'dark/primary button on the hero': 2.22,
  // Spec §2.3: primary is 3.01:1 on the dark page; text and glyphs there
  // read primaryText.
  'dark/primary on page': 3.0,
};

List<_Pair> _pairs(ColorScheme scheme, MxSemanticColors semantic) {
  final page = scheme.surface;
  final card = semantic.cardSurface;
  final low = scheme.surfaceContainerLow;
  return [
    for (final (ground, where) in [
      (page, 'page'),
      (card, 'card'),
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
      ('info on $where', semantic.info, ground, _text),
      ('outline on $where', scheme.outline, ground, _nonText),
      ('focusRing on $where', semantic.focusRing, ground, _nonText),
    ],
    // Spec §2.3: primary is a fill; on the dark page it is not a text colour.
    ('primary on page', scheme.primary, page, _text),
    ('reviewing bars on the card', semantic.statusReviewing, card, _nonText),
    ('learning bars on the card', semantic.statusLearning, card, _nonText),
    ('mastered bars on the card', semantic.statusMastered, card, _nonText),
    // MxLinearProgress (spec §6) and the donut's arcs on their track.
    for (final (fill, name) in [
      (semantic.mastery, 'progress'),
      (semantic.statusLearning, 'learning'),
      (semantic.statusReviewing, 'reviewing'),
      (semantic.statusMastered, 'mastered'),
    ])
      ('$name fill on its track', fill, MasteryRamp.track(scheme), _nonText),
    ('snackbar message', scheme.onInverseSurface, scheme.inverseSurface, _text),
    ('snackbar action', scheme.inversePrimary, scheme.inverseSurface, _text),
    ('onPrimary on primary', scheme.onPrimary, scheme.primary, _text),
    ('onWarning on warning', semantic.onWarning, semantic.warning, _text),
    ('onMastery on mastery', semantic.onMastery, semantic.mastery, _text),
    (
      'onErrorFill on errorFill',
      semantic.onErrorFill,
      semantic.errorFill,
      _text,
    ),
    (
      'toggle off thumb on its track',
      scheme.outline,
      semantic.neutralTrack,
      _nonText,
    ),
    (
      'toggle on thumb on its track',
      scheme.onPrimary,
      semantic.primaryTrack,
      _nonText,
    ),
    ('sheet grabber', scheme.onSurfaceVariant, card, _nonText),
    // The selected navigation destination (spec §6).
    (
      'nav glyph on its pill',
      scheme.onSecondaryContainer,
      scheme.secondaryContainer,
      _nonText,
    ),
    (
      'search placeholder',
      scheme.onSurfaceVariant,
      semantic.searchSurface,
      _text,
    ),
    // A deck's tile (spec §2.2): the info glyph in light, the info container
    // in dark.
    (
      'deck glyph on its tile',
      scheme.brightness == Brightness.dark
          ? semantic.infoContainer
          : semantic.info,
      semantic.tileSurface,
      _nonText,
    ),
    (
      'onInfoContainer on infoContainer',
      semantic.onInfoContainer,
      semantic.infoContainer,
      _text,
    ),
    // Soft grounds are their colour at 16% over the surface, in both
    // themes (spec §2): the tone's text, and the neutral message a banner
    // or a toned card keeps.
    for (final (fore, ground, name) in [
      (semantic.onPrimarySoft, semantic.primarySoft, 'primarySoft'),
      (semantic.onSuccessSoft, semantic.successSoft, 'successSoft'),
      (semantic.onLearningSoft, semantic.learningSoft, 'learningSoft'),
      (semantic.onWarningSoft, semantic.warningSoft, 'warningSoft'),
      (semantic.onDangerSoft, semantic.dangerSoft, 'dangerSoft'),
      (semantic.onNeutralSoft, semantic.neutralSoft, 'neutralSoft'),
    ]) ...[
      ('on$name on $name', fore, ground, _text),
      ('onSurface on $name', scheme.onSurface, ground, _text),
      ('onSurfaceVariant on $name', scheme.onSurfaceVariant, ground, _text),
    ],
    // The hero card is the primary soft ground (owner 2026-10-13): the
    // donut's band labels, the primary button and the row text on it.
    for (final (fore, name) in [
      (semantic.learningText, 'learning label'),
      (semantic.primaryText, 'reviewing label'),
      (semantic.masteryText, 'mastered label'),
    ])
      ('$name on the hero', fore, semantic.primarySoft, _text),
    (
      'primary button on the hero',
      scheme.primary,
      semantic.primarySoft,
      _nonText,
    ),
    ('onSoft on warningSoft', semantic.onSoft, semantic.warningSoft, _text),
    ('onSoft on successSoft', semantic.onSoft, semantic.successSoft, _text),
    // A seeded icon tile's glyph on its primary soft ground (MxIconTile).
    (
      'streak glyph on its tile',
      semantic.streak,
      semantic.primarySoft,
      _nonText,
    ),
    // A Guess option out of play fades as a whole to AppOpacity.muted.
    (
      'faded choice text',
      _tint(scheme.onSurface, AppOpacity.muted, page),
      _tint(card, AppOpacity.muted, page),
      _text,
    ),
  ];
}

const _themes = [
  ('light', MxSemanticColors.light),
  ('dark', MxSemanticColors.dark),
];

ColorScheme _scheme(String theme) =>
    theme == 'light' ? AppColorSchemes.light : AppColorSchemes.dark;

void main() {
  for (final (theme, semantic) in _themes) {
    group('$theme palette contrast', () {
      final pairs = _pairs(_scheme(theme), semantic);
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

  // Spec §2.3, the owner's measured table: each ratio to two places.
  group('spec §2.3 ratios', () {
    final light = AppColorSchemes.light;
    final dark = AppColorSchemes.dark;
    const day = MxSemanticColors.light;
    const night = MxSemanticColors.dark;
    final table = <(String, double, double)>[
      (
        'onSurface on surface',
        _contrast(light.onSurface, light.surface),
        _contrast(dark.onSurface, dark.surface),
      ),
      (
        'onSurfaceVariant on surface',
        _contrast(light.onSurfaceVariant, light.surface),
        _contrast(dark.onSurfaceVariant, dark.surface),
      ),
      (
        'onSurface on cardSurface',
        _contrast(light.onSurface, day.cardSurface),
        _contrast(dark.onSurface, night.cardSurface),
      ),
      (
        'onSurfaceVariant on cardSurface',
        _contrast(light.onSurfaceVariant, day.cardSurface),
        _contrast(dark.onSurfaceVariant, night.cardSurface),
      ),
      (
        'onSuccessSoft on successSoft',
        _contrast(day.onSuccessSoft, day.successSoft),
        _contrast(night.onSuccessSoft, night.successSoft),
      ),
      (
        'onWarningSoft on warningSoft',
        _contrast(day.onWarningSoft, day.warningSoft),
        _contrast(night.onWarningSoft, night.warningSoft),
      ),
      (
        'onDangerSoft on dangerSoft',
        _contrast(day.onDangerSoft, day.dangerSoft),
        _contrast(night.onDangerSoft, night.dangerSoft),
      ),
      (
        'onPrimarySoft on primarySoft',
        _contrast(day.onPrimarySoft, day.primarySoft),
        _contrast(night.onPrimarySoft, night.primarySoft),
      ),
      (
        'onNeutralSoft on neutralSoft',
        _contrast(day.onNeutralSoft, day.neutralSoft),
        _contrast(night.onNeutralSoft, night.neutralSoft),
      ),
      (
        'onMastery on mastery',
        _contrast(day.onMastery, day.mastery),
        _contrast(night.onMastery, night.mastery),
      ),
      (
        'onWarning on warning',
        _contrast(day.onWarning, day.warning),
        _contrast(night.onWarning, night.warning),
      ),
      (
        'onErrorFill on errorFill',
        _contrast(day.onErrorFill, day.errorFill),
        _contrast(night.onErrorFill, night.errorFill),
      ),
    ];
    const expected = <String, (double, double)>{
      'onSurface on surface': (17.10, 15.00),
      'onSurfaceVariant on surface': (9.40, 11.36),
      'onSurface on cardSurface': (15.24, 11.87),
      'onSurfaceVariant on cardSurface': (8.38, 8.99),
      'onSuccessSoft on successSoft': (5.06, 8.54),
      'onWarningSoft on warningSoft': (5.10, 8.96),
      'onDangerSoft on dangerSoft': (4.89, 8.48),
      'onPrimarySoft on primarySoft': (5.06, 8.42),
      'onNeutralSoft on neutralSoft': (4.59, 4.60),
      'onMastery on mastery': (4.57, 4.57),
      'onWarning on warning': (4.58, 4.58),
      'onErrorFill on errorFill': (6.46, 7.72),
    };
    for (final (name, lightRatio, darkRatio) in table) {
      test(name, () {
        final (wantLight, wantDark) = expected[name]!;
        expect(lightRatio, closeTo(wantLight, 0.01), reason: 'light');
        expect(darkRatio, closeTo(wantDark, 0.01), reason: 'dark');
      });
    }
    test('primary on the dark surface is 3.01', () {
      expect(_contrast(dark.primary, dark.surface), closeTo(3.01, 0.01));
    });
  });

  test('every exception names a checked pair', () {
    final names = {
      for (final (theme, semantic) in _themes)
        for (final pair in _pairs(_scheme(theme), semantic))
          '$theme/${pair.$1}',
    };
    expect(names.containsAll(_exceptions.keys), isTrue);
  });
}

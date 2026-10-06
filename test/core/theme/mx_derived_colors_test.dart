import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

import '../../support/color_matchers.dart';

// Expected values are worked by hand from the handoff mix ratios, not
// recomputed with the code under test.
void main() {
  final light = MxDerivedColors.resolve(
    AppColorSchemes.light,
    MxSemanticColors.light,
  );
  final dark = MxDerivedColors.resolve(
    AppColorSchemes.dark,
    MxSemanticColors.dark,
  );

  test('outlineEdge: light raises outline\'s saturation to 30% alone; dark '
      'pulls outline 20% toward onSurface (DEV-179)', () {
    final lightOutline = HSLColor.fromColor(AppColorSchemes.light.outline);
    final lightEdge = HSLColor.fromColor(light.outlineEdge);
    expect(lightEdge.hue, closeTo(lightOutline.hue, 1));
    expect(lightEdge.lightness, closeTo(lightOutline.lightness, 0.005));
    expect(lightEdge.saturation, closeTo(0.30, 0.005));
    expect(
      dark.outlineEdge,
      Color.lerp(
        AppColorSchemes.dark.outline,
        AppColorSchemes.dark.onSurface,
        0.20,
      ),
    );
    expect(
      MxDerivedColors.outlineEdgeOf(AppColorSchemes.light),
      light.outlineEdge,
    );
  });

  test('dangerSoft: error at 8% light, 16% dark', () {
    expect(light.dangerSoft, isColorCloseTo(0x14C02447));
    expect(dark.dangerSoft, isColorCloseTo(0x29FF8FA3));
  });

  test('dangerBorder: error at 22% light, 32% dark', () {
    expect(light.dangerBorder, isColorCloseTo(0x38C02447));
    expect(dark.dangerBorder, isColorCloseTo(0x52FF8FA3));
  });

  test('warningSoft: warning at 12% light, 18% dark', () {
    expect(light.warningSoft, isColorCloseTo(0x1FF59E0B));
    expect(dark.warningSoft, isColorCloseTo(0x2EFFC658));
  });

  test('successSoft: success at 10% light, 18% dark (FE-A6 D14)', () {
    expect(light.successSoft, isColorCloseTo(0x1A2BA88B));
    expect(dark.successSoft, isColorCloseTo(0x2E6FE0BD));
  });

  test('successBorder: success at 26% light, 32% dark', () {
    expect(light.successBorder, isColorCloseTo(0x422BA88B));
    expect(dark.successBorder, isColorCloseTo(0x526FE0BD));
  });

  for (final (name, scheme, derived) in [
    ('light', AppColorSchemes.light, light),
    ('dark', AppColorSchemes.dark, dark),
  ]) {
    test('successInk reads 4.5:1 on the surface and on its soft tint '
        '($name)', () {
      final soft = Color.alphaBlend(derived.successSoft, scheme.surface);

      expect(
        _ratio(derived.successInk, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(_ratio(derived.successInk, soft), greaterThanOrEqualTo(4.5));
    });
  }

  test('surfaceHero blends over surfaceBright in light, surface in dark', () {
    // Light: #5265F5 at 5% over #FFFFFF. Dark: #5265F5 at 18% over #0A0E27.
    expect(light.surfaceHero, isColorCloseTo(0xFFF6F7FE));
    expect(dark.surfaceHero, isColorCloseTo(0xFF171E4C));
  });

  test('the dark hero lifts off the page and its boxed tiles as the kit '
      'hero did (#8B9AFF at 12%: 1.19 and 1.06)', () {
    final scheme = AppColorSchemes.dark;
    expect(
      _ratio(dark.surfaceHero, scheme.surface),
      greaterThanOrEqualTo(1.19),
    );
    expect(
      _ratio(dark.surfaceHero, scheme.surfaceContainerLowest),
      greaterThanOrEqualTo(1.06),
    );
  });

  test('chromeGlass is surface at the glass opacity, not pre-flattened', () {
    expect(light.chromeGlass, isColorCloseTo(0xD6F7F9FE));
    expect(dark.chromeGlass, isColorCloseTo(0xD60A0E27));
  });

  test('ghostBorder is primary at 14% light, 16% dark', () {
    expect(light.ghostBorder, isColorCloseTo(0x245265F5));
    expect(dark.ghostBorder, isColorCloseTo(0x295265F5));
  });

  test('warningInk is #895806 in light and the amber in dark (critique '
      '2026-09-30 tone pass, T1)', () {
    expect(light.warningInk, isColorCloseTo(0xFF895806));
    expect(dark.warningInk, MxSemanticColors.dark.warning);
  });

  test('warningInk reads at 4.5:1 on every ground, the amber tint and the '
      'warning ground (T1)', () {
    for (final (scheme, semantic) in [
      (AppColorSchemes.light, MxSemanticColors.light),
      (AppColorSchemes.dark, MxSemanticColors.dark),
    ]) {
      final derived = MxDerivedColors.resolve(scheme, semantic);
      for (final ground in [
        scheme.surface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainer,
        // The sheet and dialog ground.
        scheme.surfaceContainerHigh,
      ]) {
        final tint = Color.alphaBlend(
          semantic.warning.withValues(alpha: 0.12),
          ground,
        );
        final soft = Color.alphaBlend(derived.warningSoft, ground);
        expect(_ratio(derived.warningInk, ground), greaterThanOrEqualTo(4.5));
        expect(_ratio(derived.warningInk, tint), greaterThanOrEqualTo(4.5));
        expect(_ratio(derived.warningInk, soft), greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('dangerInk is error pulled toward onSurface, 10% light and 30% dark '
      '(critique 2026-09-30 tone pass, final review)', () {
    expect(light.dangerInk, isColorCloseTo(0xFFAE2346));
    expect(dark.dangerInk, isColorCloseTo(0xFFF7AABD));
  });

  test('dangerInk reads at 4.5:1 on the danger ground over every surface, '
      'the sheet included', () {
    for (final (scheme, semantic) in [
      (AppColorSchemes.light, MxSemanticColors.light),
      (AppColorSchemes.dark, MxSemanticColors.dark),
    ]) {
      final derived = MxDerivedColors.resolve(scheme, semantic);
      for (final ground in [
        scheme.surface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
      ]) {
        final soft = Color.alphaBlend(derived.dangerSoft, ground);
        expect(_ratio(derived.dangerInk, soft), greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('warningBorder: warning at 26% light, 32% dark (O6)', () {
    expect(light.warningBorder, isColorCloseTo(0x42F59E0B));
    expect(dark.warningBorder, isColorCloseTo(0x52FFC658));
  });

  test('status inks reach 4.5:1 on every ground and tint (L6)', () {
    for (final (scheme, semantic) in [
      (AppColorSchemes.light, MxSemanticColors.light),
      (AppColorSchemes.dark, MxSemanticColors.dark),
    ]) {
      final derived = MxDerivedColors.resolve(scheme, semantic);
      for (final (status, ink) in [
        (semantic.statusNew, derived.statusNewInk),
        (semantic.statusLearning, derived.statusLearningInk),
        (semantic.statusReviewing, derived.statusReviewingInk),
        (semantic.statusMastered, derived.statusMasteredInk),
      ]) {
        for (final ground in [
          scheme.surface,
          scheme.surfaceContainerLowest,
          scheme.surfaceContainer,
        ]) {
          final tint = Color.alphaBlend(status.withValues(alpha: 0.12), ground);
          expect(_ratio(ink, ground), greaterThanOrEqualTo(4.5));
          expect(_ratio(ink, tint), greaterThanOrEqualTo(4.5));
        }
      }
    }
  });

  testWidgets('derived colours resolve once per theme', (tester) async {
    late MxDerivedColors first;
    late MxDerivedColors second;
    Widget probe(ThemeData theme) => MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          first = context.derivedColors;
          second = context.derivedColors;
          return const SizedBox();
        },
      ),
    );

    await tester.pumpWidget(probe(buildLightTheme()));
    expect(identical(first, second), isTrue);
    final light = first;

    await tester.pumpWidget(probe(buildDarkTheme()));
    // MaterialApp animates the switch; the settled frame reads dark.
    await tester.pumpAndSettle();
    expect(identical(first, light), isFalse);
    expect(first.ghostBorder, isNot(light.ghostBorder));
  });

  group('primaryInk (spec 2026-09-27 D2)', () {
    for (final (name, scheme, derived) in [
      ('light', AppColorSchemes.light, light),
      ('dark', AppColorSchemes.dark, dark),
    ]) {
      final grounds = [
        scheme.surface,
        scheme.surfaceBright,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        derived.surfaceHero,
      ];
      // Primary tints sit on the page, a card or a sheet (nav pill, badge,
      // tag chip, command row), never on the higher containers.
      final tinted = [
        scheme.surface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
      ];
      test('$name: 4.5:1 on every ground and on primary tints', () {
        for (final ground in grounds) {
          expect(_ratio(derived.primaryInk, ground), greaterThanOrEqualTo(4.5));
        }
        for (final ground in tinted) {
          for (final alpha in [0.08, 0.10, 0.12, 0.16, 0.20]) {
            final tint = Color.alphaBlend(
              scheme.primary.withValues(alpha: alpha),
              ground,
            );
            expect(_ratio(derived.primaryInk, tint), greaterThanOrEqualTo(4.5));
          }
        }
      });
      test('$name: an indigo between primary and onSurface', () {
        expect(derived.primaryInk, isNot(scheme.primary));
        expect(derived.primaryInk, isNot(scheme.onSurface));
        expect(derived.primaryInk, MxDerivedColors.primaryInkOf(scheme));
      });
    }
  });
}

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

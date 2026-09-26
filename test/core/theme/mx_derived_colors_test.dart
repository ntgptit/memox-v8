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

  test('dangerSoft: error at 8% light, 16% dark', () {
    expect(light.dangerSoft, isColorCloseTo(0x14DC2D4E));
    expect(dark.dangerSoft, isColorCloseTo(0x29FF8FA3));
  });

  test('dangerBorder: error at 22% light, 32% dark', () {
    expect(light.dangerBorder, isColorCloseTo(0x38DC2D4E));
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
    // Light: #5265F5 at 5% over #FFFFFF. Dark: #5265F5 at 12% over #0A0E27.
    expect(light.surfaceHero, isColorCloseTo(0xFFF6F7FE));
    expect(dark.surfaceHero, isColorCloseTo(0xFF131840));
  });

  test('chromeGlass is surface at the glass opacity, not pre-flattened', () {
    expect(light.chromeGlass, isColorCloseTo(0xD6F7F9FE));
    expect(dark.chromeGlass, isColorCloseTo(0xD60A0E27));
  });

  test('ghostBorder is primary at 14% light, 16% dark', () {
    expect(light.ghostBorder, isColorCloseTo(0x245265F5));
    expect(dark.ghostBorder, isColorCloseTo(0x295265F5));
  });

  test('warningInk is onWarning in light and the amber in dark (I1)', () {
    expect(light.warningInk, MxSemanticColors.light.onWarning);
    expect(dark.warningInk, MxSemanticColors.dark.warning);
  });

  test('warningBorder: warning at 26% light, 32% dark (O6)', () {
    expect(light.warningBorder, isColorCloseTo(0x42F59E0B));
    expect(dark.warningBorder, isColorCloseTo(0x52FFC658));
  });

  test('status inks reach 4.5:1 on every ground and tint (L6)', () {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final (hi, lo) = la > lb ? (la, lb) : (lb, la);
      return (hi + 0.05) / (lo + 0.05);
    }

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
          expect(ratio(ink, ground), greaterThanOrEqualTo(4.5));
          expect(ratio(ink, tint), greaterThanOrEqualTo(4.5));
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

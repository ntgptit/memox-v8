import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

void main() {
  for (final (scheme, semantic, name) in [
    (AppColorSchemes.light, MxSemanticColors.light, 'light'),
    (AppColorSchemes.dark, MxSemanticColors.dark, 'dark'),
  ]) {
    test('$name fill: null at 0, warning under 0.34, primary under 0.67, '
        'mastery from 0.67', () {
      expect(MasteryRamp.fill(semantic, scheme, 0), isNull);
      expect(MasteryRamp.fill(semantic, scheme, 0.01), semantic.warning);
      expect(MasteryRamp.fill(semantic, scheme, 0.3399), semantic.warning);
      expect(MasteryRamp.fill(semantic, scheme, 0.34), scheme.primary);
      expect(MasteryRamp.fill(semantic, scheme, 0.6699), scheme.primary);
      expect(MasteryRamp.fill(semantic, scheme, 0.67), semantic.mastery);
      expect(MasteryRamp.fill(semantic, scheme, 1), semantic.mastery);
    });

    test(
      '$name foreground: the band role, primaryForeground for reviewing',
      () {
        expect(MasteryRamp.foreground(semantic, scheme, 0), semantic.warning);
        expect(
          MasteryRamp.foreground(semantic, scheme, 0.5),
          semantic.primaryForeground,
        );
        expect(MasteryRamp.foreground(semantic, scheme, 0.9), semantic.mastery);
      },
    );
  }

  test('a fraction outside [0, 1] or NaN is rejected, not painted', () {
    const semantic = MxSemanticColors.light;
    final scheme = AppColorSchemes.light;
    for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
      expect(
        () => MasteryRamp.fill(semantic, scheme, bad),
        throwsArgumentError,
        reason: '$bad',
      );
      expect(
        () => MasteryRamp.foreground(semantic, scheme, bad),
        throwsArgumentError,
        reason: '$bad',
      );
      expect(
        () => MasteryRamp.percent(bad),
        throwsArgumentError,
        reason: '$bad',
      );
    }
  });

  test('the percent never rounds to a lie: 0 only at 0, 100 only at 1 '
      '(deck mastery spec D13)', () {
    expect(
      [
        for (final f in [0.0, 0.0001, 0.004, 0.1635, 0.5, 0.996, 0.9999, 1.0])
          MasteryRamp.percent(f),
      ],
      [0, 1, 1, 16, 50, 99, 99, 100],
    );
  });

  test('the track is surfaceContainerLow, so a primary fill keeps 3:1 '
      'in dark (FE-C1)', () {
    for (final scheme in [AppColorSchemes.light, AppColorSchemes.dark]) {
      expect(MasteryRamp.track(scheme), scheme.surfaceContainerLow);
    }
  });
}

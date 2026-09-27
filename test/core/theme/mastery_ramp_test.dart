import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

void main() {
  const semantic = MxSemanticColors.light;
  final derived = MxDerivedColors.resolve(AppColorSchemes.light, semantic);

  test('0% paints no fill, only the track', () {
    expect(MasteryRamp.fill(semantic, derived, 0), isNull);
  });

  test('below 34% is the learning ink (deck mastery spec R4)', () {
    expect(
      MasteryRamp.fill(semantic, derived, 0.01),
      derived.statusLearningInk,
    );
    expect(
      MasteryRamp.fill(semantic, derived, 0.3399),
      derived.statusLearningInk,
    );
  });

  test('in dark the learning ink is the kit amber itself', () {
    const dark = MxSemanticColors.dark;
    final darkDerived = MxDerivedColors.resolve(AppColorSchemes.dark, dark);
    expect(MasteryRamp.fill(dark, darkDerived, 0.2), dark.statusLearning);
  });

  test('34% up to 67% is reviewing', () {
    expect(MasteryRamp.fill(semantic, derived, 0.34), semantic.statusReviewing);
    expect(
      MasteryRamp.fill(semantic, derived, 0.6699),
      semantic.statusReviewing,
    );
  });

  test('67% and above is mastered', () {
    expect(MasteryRamp.fill(semantic, derived, 0.67), semantic.statusMastered);
    expect(MasteryRamp.fill(semantic, derived, 1), semantic.statusMastered);
  });

  test('a fraction outside [0, 1] or NaN is rejected, not painted', () {
    for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
      expect(
        () => MasteryRamp.fill(semantic, derived, bad),
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

  test('the track is surfaceContainerHigh (progress-track)', () {
    expect(
      MasteryRamp.track(AppColorSchemes.light),
      AppColorSchemes.light.surfaceContainerHigh,
    );
  });
}

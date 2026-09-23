import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

void main() {
  const semantic = MxSemanticColors.light;

  test('0% paints no fill, only the track', () {
    expect(MasteryRamp.fill(semantic, 0), isNull);
  });

  test('below 34% is learning', () {
    expect(MasteryRamp.fill(semantic, 0.01), semantic.statusLearning);
    expect(MasteryRamp.fill(semantic, 0.3399), semantic.statusLearning);
  });

  test('34% up to 67% is reviewing', () {
    expect(MasteryRamp.fill(semantic, 0.34), semantic.statusReviewing);
    expect(MasteryRamp.fill(semantic, 0.6699), semantic.statusReviewing);
  });

  test('67% and above is mastered', () {
    expect(MasteryRamp.fill(semantic, 0.67), semantic.statusMastered);
    expect(MasteryRamp.fill(semantic, 1), semantic.statusMastered);
  });

  test('a fraction outside [0, 1] or NaN is rejected, not painted', () {
    for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
      expect(
        () => MasteryRamp.fill(semantic, bad),
        throwsArgumentError,
        reason: '$bad',
      );
    }
  });

  test('the track is surfaceContainerHigh (progress-track)', () {
    expect(
      MasteryRamp.track(AppColorSchemes.light),
      AppColorSchemes.light.surfaceContainerHigh,
    );
  });
}

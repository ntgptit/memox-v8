import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

void main() {
  const semantic = MxSemanticColors.light;

  group('fill', () {
    test('is null at 0, where only the track paints', () {
      expect(MasteryRamp.fill(semantic, 0), isNull);
    });
    for (final (fraction, expected) in [
      (0.01, semantic.statusLearning),
      (0.33, semantic.statusLearning),
      (0.34, semantic.statusReviewing),
      (0.66, semantic.statusReviewing),
      (0.67, semantic.statusMastered),
      (1.0, semantic.statusMastered),
    ]) {
      test('at $fraction is the band fill', () {
        expect(MasteryRamp.fill(semantic, fraction), expected);
      });
    }
  });

  group('label', () {
    for (final (fraction, expected) in [
      (0.0, semantic.learningText),
      (0.33, semantic.learningText),
      (0.34, semantic.primaryText),
      (0.66, semantic.primaryText),
      (0.67, semantic.masteryText),
      (1.0, semantic.masteryText),
    ]) {
      test('at $fraction is the band text token', () {
        expect(MasteryRamp.label(semantic, fraction), expected);
      });
    }
    test('reads the Night tokens in Night', () {
      const dark = MxSemanticColors.dark;
      expect(MasteryRamp.label(dark, 0.5), dark.primaryText);
    });
  });

  test('a fraction outside [0, 1] or NaN is rejected, not painted', () {
    for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
      expect(
        () => MasteryRamp.fill(semantic, bad),
        throwsArgumentError,
        reason: '$bad',
      );
      expect(
        () => MasteryRamp.label(semantic, bad),
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

  test('the track is surfaceContainerLow', () {
    for (final scheme in [AppColorSchemes.light, AppColorSchemes.dark]) {
      expect(MasteryRamp.track(scheme), scheme.surfaceContainerLow);
    }
  });
}

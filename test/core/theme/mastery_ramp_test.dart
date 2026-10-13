import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/mastery_ramp.dart';

void main() {
  const mx = MxColorsExtension.light;
  final accent = lightColorScheme.primary;

  test('0% paints no fill, only the track', () {
    expect(MasteryRamp.fill(mx, accent, 0), isNull);
  });

  test('below 34% is the warning colour (deck mastery spec R4)', () {
    expect(MasteryRamp.fill(mx, accent, 0.01), mx.warning);
    expect(MasteryRamp.fill(mx, accent, 0.3399), mx.warning);
  });

  test('34% up to 67% is the accent', () {
    expect(MasteryRamp.fill(mx, accent, 0.34), accent);
    expect(MasteryRamp.fill(mx, accent, 0.6699), accent);
  });

  test('67% and above is the success container', () {
    expect(MasteryRamp.fill(mx, accent, 0.67), mx.successContainer);
    expect(MasteryRamp.fill(mx, accent, 1), mx.successContainer);
  });

  test('the text foreground is the band\'s own text colour, never the fill '
      '(SW-REV-001); 0% reads in the lowest band', () {
    expect(MasteryRamp.foreground(mx, accent, 0), mx.warning);
    expect(MasteryRamp.foreground(mx, accent, 0.3399), mx.warning);
    expect(MasteryRamp.foreground(mx, accent, 0.34), accent);
    expect(MasteryRamp.foreground(mx, accent, 0.67), mx.success);
    expect(MasteryRamp.foreground(mx, accent, 1), mx.success);
  });

  test('a fraction outside [0, 1] or NaN is rejected, not painted', () {
    for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
      expect(
        () => MasteryRamp.fill(mx, accent, bad),
        throwsArgumentError,
        reason: '$bad',
      );
      expect(
        () => MasteryRamp.foreground(mx, accent, bad),
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

  test('the track is the highest surface container', () {
    for (final scheme in [lightColorScheme, darkColorScheme]) {
      expect(MasteryRamp.track(scheme), scheme.surfaceContainerHighest);
    }
  });
}

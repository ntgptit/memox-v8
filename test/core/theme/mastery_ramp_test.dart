import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

void main() {
  const status = MxStatusColors.light;
  final accent = appLightColors.primary;

  test('0% paints no fill, only the track', () {
    expect(MasteryRamp.fill(status, accent, 0), isNull);
  });

  test('below 34% is the warning fill (deck mastery spec R4)', () {
    expect(MasteryRamp.fill(status, accent, 0.01), status.warningFill);
    expect(MasteryRamp.fill(status, accent, 0.3399), status.warningFill);
  });

  test('34% up to 67% is the primary colour', () {
    expect(MasteryRamp.fill(status, accent, 0.34), accent);
    expect(MasteryRamp.fill(status, accent, 0.6699), accent);
  });

  test('67% and above is the success fill', () {
    expect(MasteryRamp.fill(status, accent, 0.67), status.successFill);
    expect(MasteryRamp.fill(status, accent, 1), status.successFill);
  });

  test("the text foreground is the band's own ink, never the fill "
      '(SW-REV-001); 0% reads in the lowest band', () {
    expect(MasteryRamp.foreground(status, accent, 0), status.warning);
    expect(MasteryRamp.foreground(status, accent, 0.2), status.warning);
    expect(MasteryRamp.foreground(status, accent, 0.5), accent);
    expect(MasteryRamp.foreground(status, accent, 0.9), status.success);
  });

  test('a fraction outside [0, 1] or NaN is rejected, not painted', () {
    for (final bad in [-0.01, 1.01, double.nan]) {
      expect(() => MasteryRamp.fill(status, accent, bad), throwsArgumentError);
      expect(
        () => MasteryRamp.foreground(status, accent, bad),
        throwsArgumentError,
      );
      expect(() => MasteryRamp.percent(bad), throwsArgumentError);
    }
  });

  test('the percent never rounds to a lie (deck mastery spec D13)', () {
    expect(MasteryRamp.percent(0), 0);
    expect(MasteryRamp.percent(0.001), 1);
    expect(MasteryRamp.percent(0.5), 50);
    expect(MasteryRamp.percent(0.999), 99);
    expect(MasteryRamp.percent(1), 100);
  });

  test("the track is ForUI's progress track, muted", () {
    expect(MasteryRamp.track(appLightColors), appLightColors.muted);
  });
}

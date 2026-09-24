import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
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

  test('surfaceHero blends over surfaceBright in light, surface in dark', () {
    // Light: #5265F5 at 5% over #FFFFFF. Dark: #8B9AFF at 12% over #0A0E27.
    expect(light.surfaceHero, isColorCloseTo(0xFFF6F7FE));
    expect(dark.surfaceHero, isColorCloseTo(0xFF191F41));
  });

  test('chromeGlass is surface at the glass opacity, not pre-flattened', () {
    expect(light.chromeGlass, isColorCloseTo(0xD6F7F9FE));
    expect(dark.chromeGlass, isColorCloseTo(0xD60A0E27));
  });

  test('ghostBorder is primary at 14% light, 16% dark', () {
    expect(light.ghostBorder, isColorCloseTo(0x245265F5));
    expect(dark.ghostBorder, isColorCloseTo(0x298B9AFF));
  });

  test('warningInk is onWarning in light and the amber in dark (I1)', () {
    expect(light.warningInk, MxSemanticColors.light.onWarning);
    expect(dark.warningInk, MxSemanticColors.dark.warning);
  });

  test('warningBorder: warning at 26% light, 32% dark (O6)', () {
    expect(light.warningBorder, isColorCloseTo(0x42F59E0B));
    expect(dark.warningBorder, isColorCloseTo(0x52FFC658));
  });
}

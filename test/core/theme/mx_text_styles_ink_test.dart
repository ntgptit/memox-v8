import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Primary as text reads in primaryInk, never the fill (spec 2026-09-27 D2).
void main() {
  for (final (name, theme, scheme) in [
    ('light', buildLightTheme(), AppColorSchemes.light),
    ('dark', buildDarkTheme(), AppColorSchemes.dark),
  ]) {
    test('$name: primary-coloured styles ink in primaryInk', () {
      final styles = MxTextStyles(theme.textTheme, scheme);
      final ink = MxDerivedColors.primaryInkOf(scheme);
      expect(styles.navLabel(isSelected: true).color, ink);
      expect(styles.disclosureLabel.color, ink);
      expect(styles.rowTitleMatch.color, ink);
      expect(styles.requiredMarker.color, ink);
      expect(styles.removableTagLabel.color, ink);
    });
  }
}

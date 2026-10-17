import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' as mu;
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

// Where ForUI draws the brand as a mark, an edge or a selected label, the
// theme draws it in the brand's ink: on the dark navy page primary is a
// fill under white text, too dark to read as text or as a 3:1 mark. Light's
// ink is primary itself, so light is ForUI's default (owner ruling
// 2026-10-17).
void main() {
  for (final (mode, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    group(mode, () {
      final ink = theme.colors.extension<MxStatusColors>().primaryInk;

      test('the focus outline is the ink', () {
        expect(theme.style.focusedOutlineStyle.color, ink);
      });

      test('a ticked checkbox is filled with the ink', () {
        final box = theme.checkboxStyle.decoration.resolve({
          FCheckboxVariant.selected,
        }) as ShapeDecoration;
        expect(box.color, ink);
      });

      test('the tick reads on the ink at 4.5:1', () {
        final tick = theme.checkboxStyle.iconStyle.resolve({
          FCheckboxVariant.selected,
        }).color!;
        expect(_contrast(tick, ink), greaterThanOrEqualTo(4.5));
      });

      test('a switch that is on has an ink track', () {
        expect(
          theme.switchStyle.trackColor.resolve({FSwitchVariant.selected}),
          ink,
        );
      });

      test('the slider fills in the ink', () {
        final slider = theme.sliderStyles.resolve({
          FSliderAxisVariant.horizontal,
        });
        expect(slider.activeColor.base, ink);
      });

      test('the selected tab is the ink', () {
        final item = theme.bottomNavigationBarStyle.itemStyle;
        expect(item.iconStyle.resolve({FTappableVariant.selected}).color, ink);
        expect(item.textStyle.resolve({FTappableVariant.selected}).color, ink);
      });

      test('a focused field edge and its caret are the ink', () {
        final field = theme.textFieldStyles.resolve({FTextFieldSizeVariant.md});
        final edge = field.border.resolve({
          FTextFieldVariant.focused,
        }) as mu.OutlineInputBorder;
        expect(edge.borderSide.color, ink);
        expect(field.cursorColor, ink);
      });

      test('a primary button stays a primary fill', () {
        final button = theme.buttonStyles.primary.resolve({
          FButtonSizeVariant.md,
        });
        final fill = button.decoration.base as ShapeDecoration;
        expect(fill.color, theme.colors.primary);
      });
    });
  }

  test('dark ink differs from dark primary, light ink is light primary', () {
    final dark = buildDarkTheme().colors;
    final light = buildLightTheme().colors;
    expect(dark.extension<MxStatusColors>().primaryInk, isNot(dark.primary));
    expect(light.extension<MxStatusColors>().primaryInk, light.primary);
  });
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

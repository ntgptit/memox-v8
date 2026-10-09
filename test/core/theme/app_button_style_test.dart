import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_button_style.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';

void main() {
  const fill = Color(0xFF5265F5);
  const ink = Color(0xFFFFFFFF);
  const shadow = Color(0xFF0F1638);
  ButtonStyle style({Color? focusColor}) => appButtonStyle(
    fill: fill,
    ink: ink,
    edge: BorderSide.none,
    pressedLayer: shadow,
    focusColor: focusColor,
    height: 48,
    radius: 12,
    padding: 16,
    label: const TextStyle(),
  );

  test('the pressed overlay is the pressed layer at AppOpacity.pressed', () {
    final overlay = style().overlayColor!.resolve({WidgetState.pressed});
    expect(overlay, shadow.withValues(alpha: AppOpacity.pressed));
  });

  test('no focusColor: the side never swaps on focus', () {
    expect(style().side!.resolve({WidgetState.focused}), BorderSide.none);
  });

  test('a focusColor keeps the inside ring for a raw Material button', () {
    final side = style(focusColor: ink).side!.resolve({WidgetState.focused});
    expect(side?.color, ink);
  });
}

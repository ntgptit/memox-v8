import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';

// 02-theme-binding.md, DECORATION. Light shadows are rgba(15,22,56,a), which
// is the light `shadow` role; dark ones are rgba(0,0,0,a), the dark role.
void expectShadow(
  List<BoxShadow> actual,
  ColorScheme scheme, {
  required double dy,
  required double blur,
  required double alpha,
}) {
  expect(actual, hasLength(1));
  expect(actual.single.offset, Offset(0, dy));
  expect(actual.single.blurRadius, blur);
  expect(actual.single.spreadRadius, 0);
  expect(actual.single.color, scheme.shadow.withValues(alpha: alpha));
}

void main() {
  final light = AppColorSchemes.light;
  final dark = AppColorSchemes.dark;

  test('whisper: card and toggle thumb, none in dark', () {
    expectShadow(AppShadows.whisper(light), light, dy: 1, blur: 2, alpha: 0.04);
    expect(AppShadows.whisper(dark), isEmpty);
  });

  test('overlay: the dialog shadow (source token shadow-card)', () {
    expectShadow(
      AppShadows.overlay(light),
      light,
      dy: 12,
      blur: 32,
      alpha: 0.10,
    );
    expectShadow(AppShadows.overlay(dark), dark, dy: 16, blur: 40, alpha: 0.42);
  });

  test('chrome: bottom sheet and bottom chrome, cast upward', () {
    expectShadow(
      AppShadows.chrome(light),
      light,
      dy: -2,
      blur: 12,
      alpha: 0.05,
    );
    expectShadow(AppShadows.chrome(dark), dark, dy: -2, blur: 14, alpha: 0.36);
  });

  test('fab: the floating action', () {
    expectShadow(AppShadows.fab(light), light, dy: 8, blur: 24, alpha: 0.12);
    expectShadow(AppShadows.fab(dark), dark, dy: 10, blur: 28, alpha: 0.5);
  });
}

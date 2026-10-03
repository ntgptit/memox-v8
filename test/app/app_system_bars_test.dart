import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app_system_bars.dart';
import 'package:memox/core/theme/app_theme.dart';

SystemUiOverlayStyle _style(WidgetTester tester) => tester
    .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    )
    .value;

// pumpAndSettle: a theme switch animates, and the brightness flips mid-way.
Future<void> _pump(WidgetTester tester, ThemeMode mode) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      builder: (_, child) => AppSystemBars(child: child!),
      home: const SizedBox(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the app theme, not the phone, sets the bar icons (audit P1)', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _pump(tester, ThemeMode.dark);
    expect(_style(tester).statusBarIconBrightness, Brightness.light);
    expect(_style(tester).systemNavigationBarIconBrightness, Brightness.light);

    await _pump(tester, ThemeMode.light);
    expect(_style(tester).statusBarIconBrightness, Brightness.dark);
    expect(_style(tester).systemNavigationBarContrastEnforced, isFalse);
  });
}

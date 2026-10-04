import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The text scales every design-system component is tested at
/// (spec 2026-10-04-sp3a D17).
const designSystemTextScales = [1.0, 1.3, 1.5, 2.0];

/// Pumps [child] the way the app would show it: in the light or dark theme,
/// the en or vi localization, a [width] dp wide phone screen, at
/// [textScale] and in [direction]. Every design-system test and golden goes
/// through here (spec §8.2).
Future<void> pumpDesignSystem(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double width = 360,
  double height = 800,
  double textScale = 1.0,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: SafeArea(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

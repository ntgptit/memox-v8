import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app_theme_host.dart';
import 'package:memox/core/theme/app_palette.dart';

void main() {
  // FScaffold applies the theme's system overlay style; the app keeps the
  // Material Scaffold as its host (FORUI_ARCHITECTURE.md), so the theme host
  // applies it once for every route: dark status bar icons on the light page,
  // light ones on the dark page.
  for (final (brightness, colors) in [
    (Brightness.light, appLightColors),
    (Brightness.dark, appDarkColors),
  ]) {
    testWidgets('the status bar takes the ${brightness.name} palette\'s '
        'overlay style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              AppThemeHost(brightness: brightness, child: child!),
          home: const SizedBox.expand(),
        ),
      );

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value, colors.systemOverlayStyle);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'widget_harness.dart';

const Duration _indicatorFrame = Duration(milliseconds: 300);

/// Renders [child] on each theme's page ground at 360×800 and compares it
/// with `goldens/<name>_light.png` and `goldens/<name>_dark.png` beside the
/// calling test file.
Future<void> expectThemedGoldens(
  WidgetTester tester,
  String name,
  Widget child,
) async {
  await tester.binding.setSurfaceSize(phoneSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  for (final (suffix, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        // Otherwise the second pump still paints the previous theme.
        themeAnimationDuration: Duration.zero,
        theme: theme,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
    // A fixed step, so an indeterminate indicator shows its arc
    // deterministically instead of its empty first frame.
    await tester.pump(_indicatorFrame);
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/${name}_$suffix.png'),
    );
  }
}

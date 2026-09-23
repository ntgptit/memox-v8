import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'widget_harness.dart';

const Duration _indicatorFrame = Duration(milliseconds: 300);

/// A phone's pixel density. matchesGoldenFile on a Finder always captures at
/// 1.0, which makes text and rounded corners visibly jagged, so the harness
/// captures the boundary itself at this ratio.
const double _goldenPixelRatio = 3;

const Key _boundaryKey = ValueKey('golden-boundary');

/// Renders [child] on each theme's page ground at 360×800 logical pixels and
/// compares it, captured at 3x, with `goldens/<name>_light.png` and
/// `goldens/<name>_dark.png` beside the calling test file.
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
      RepaintBoundary(
        key: _boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // Otherwise the second pump still paints the previous theme.
          themeAnimationDuration: Duration.zero,
          theme: theme,
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
    // A fixed step, so an indeterminate indicator shows its arc
    // deterministically instead of its empty first frame.
    await tester.pump(_indicatorFrame);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final image = await tester.runAsync(
      () => boundary.toImage(pixelRatio: _goldenPixelRatio),
    );
    await expectLater(image, matchesGoldenFile('goldens/${name}_$suffix.png'));
    image!.dispose();
  }
}

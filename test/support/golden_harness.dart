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

/// Wrap the tree a golden captures in a RepaintBoundary with this key.
const Key goldenBoundaryKey = ValueKey('golden-boundary');

/// Runs [body] with shadow blur painted for real: flutter_test's default
/// draws shadows as hard shapes, and the shadow treatments are design truth.
/// Restores the default before the test's invariant check.
Future<void> withRealShadows(Future<void> Function() body) async {
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = true;
  }
}

/// Compares the RepaintBoundary keyed [goldenBoundaryKey], captured at 3x,
/// with the golden at [path] beside the calling test. Call it inside
/// [withRealShadows], after pumping, so every layer was painted with blur.
Future<void> expectBoundaryGolden(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(goldenBoundaryKey),
  );
  final image = await tester.runAsync(
    () => boundary.toImage(pixelRatio: _goldenPixelRatio),
  );
  await expectLater(image, matchesGoldenFile(path));
  image!.dispose();
}

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
  await withRealShadows(() async {
    for (final (suffix, theme) in [
      ('light', buildLightTheme()),
      ('dark', buildDarkTheme()),
    ]) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: goldenBoundaryKey,
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
      await expectBoundaryGolden(tester, 'goldens/${name}_$suffix.png');
    }
  });
}

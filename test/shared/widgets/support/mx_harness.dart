import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// Both themes, by the variant name a golden carries (`light`, `dark`).
final Map<String, ThemeData> mxThemes = {
  'light': AppTheme.light(),
  'dark': AppTheme.dark(),
};

/// Pumps [child] on the theme's page ground, as a screen would show it.
Future<void> pumpMx(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? mxThemes['light'],
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// A full-HD phone's density: 1080 px across a 412 dp screen.
const double mxGoldenPixelRatio = 2.625;

/// The key of the picture a component golden captures.
const Key mxGoldenKey = ValueKey<String>('mx-golden');

/// One component golden: [sheet] laid out on the page ground of [variant]'s
/// theme at a phone's width, captured as `mx_<component>__<state>__<variant>`.
/// [focus], when given, takes keyboard focus first, so the sheet can show a
/// focused tile as a hardware keyboard would.
Future<void> expectMxGolden(
  WidgetTester tester, {
  required String component,
  required String state,
  required String variant,
  required Widget sheet,
  FocusNode? focus,
}) async {
  // A full-HD phone, 412 dp wide; the picture is rasterized at its density
  // (below), so a golden is as sharp as the device it stands for.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = mxGoldenPixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: mxThemes[variant],
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: mxGoldenKey,
            child: ColoredBox(
              color: mxThemes[variant]!.colorScheme.surface,
              child: Padding(padding: const EdgeInsets.all(16), child: sheet),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (focus != null) {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    focus.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  // `matchesGoldenFile` on a finder captures at 1 px per dp; rasterize the
  // boundary at the device density instead and compare that picture.
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byKey(mxGoldenKey),
  );
  final ui.Image picture = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: mxGoldenPixelRatio),
  ))!;
  addTearDown(picture.dispose);
  await expectLater(
    picture,
    matchesGoldenFile('goldens/mx_${component}__${state}__$variant.png'),
  );
}

/// The ring `MxFocusRing` paints: the stroke rect, or `null` when none shows.
RRect? mxFocusRingOf(WidgetTester tester, Finder control) {
  final Finder painters = find.descendant(
    of: control,
    matching: find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.foregroundPainter.runtimeType.toString() == '_RingPainter',
    ),
  );
  if (painters.evaluate().isEmpty) {
    return null;
  }
  RRect? ring;
  final CustomPaint paint = tester.widget(painters.first);
  final _RecordingCanvas canvas = _RecordingCanvas((r) => ring = r);
  paint.foregroundPainter!.paint(canvas, tester.getSize(painters.first));
  return ring;
}

/// A control reached by Tab shows the ring; one touched by a finger does not.
/// [painted] is the size the control paints, which the ring must hug.
Future<void> expectMxKeyboardRingOnly(
  WidgetTester tester,
  Widget control, {
  required Size painted,
  ThemeData? theme,
}) async {
  await pumpMx(tester, control, theme: theme);
  final Finder root = find.byWidget(control);
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
  final RRect? ring = mxFocusRingOf(tester, root);
  expect(ring, isNotNull, reason: 'Tab focus shows the ring');
  const double grow = 2 * (AppSize.focusOffset + AppStroke.focus / 2);
  expect(ring!.width, moreOrLessEquals(painted.width + grow, epsilon: 0.5));
  expect(ring.height, moreOrLessEquals(painted.height + grow, epsilon: 0.5));
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  await tester.tap(root, warnIfMissed: false);
  await tester.pump();
  expect(mxFocusRingOf(tester, root), isNull, reason: 'a tap leaves no ring');
}

class _RecordingCanvas implements Canvas {
  _RecordingCanvas(this.onRRect);

  final void Function(RRect) onRRect;

  @override
  void drawRRect(RRect rrect, Paint paint) => onRRect(rrect);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

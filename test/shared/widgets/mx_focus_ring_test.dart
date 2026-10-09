import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';

import '../../support/widget_harness.dart';

void main() {
  Widget host({
    MxFocusRingPlacement placement = MxFocusRingPlacement.outside,
  }) => MxFocusRing(
    radius: BorderRadius.circular(AppRadius.md),
    placement: placement,
    child: SizedBox(
      width: 100,
      height: 40,
      child: TextButton(onPressed: () {}, child: const Text('Go')),
    ),
  );

  // The framework paints its own CustomPaints (debug banner, Material shape
  // border), so the ring is found by its painter.
  final ring = find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint && widget.foregroundPainter is MxFocusRingPainter,
  );

  testWidgets('paints nothing while its child is not focused', (tester) async {
    await pumpMx(tester, host());
    expect(ring, findsNothing);
  });

  testWidgets('paints a primaryForeground ring outside the child on focus', (
    tester,
  ) async {
    await pumpMx(tester, host());
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final paint = tester.widget<CustomPaint>(ring);
    final painter = paint.foregroundPainter! as MxFocusRingPainter;
    expect(painter.color, MxSemanticColors.light.primaryForeground);
    expect(painter.placement, MxFocusRingPlacement.outside);
    // The ring rect is the child's rect grown by the offset and half a stroke.
    expect(painter.ringRect(const Size(100, 40)).left, -3);
    expect(painter.ringRect(const Size(100, 40)).right, 103);
  });

  testWidgets('inside placement inset the ring by the same offset', (
    tester,
  ) async {
    await pumpMx(tester, host(placement: MxFocusRingPlacement.inside));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final painter =
        tester.widget<CustomPaint>(ring).foregroundPainter!
            as MxFocusRingPainter;
    expect(painter.ringRect(const Size(100, 40)).left, 3);
    expect(painter.ringRect(const Size(100, 40)).right, 97);
  });
}

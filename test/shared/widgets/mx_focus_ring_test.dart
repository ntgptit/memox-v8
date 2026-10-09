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
    FocusNode? focusNode,
  }) => MxFocusRing(
    radius: BorderRadius.circular(AppRadius.md),
    placement: placement,
    child: SizedBox(
      width: 100,
      height: 40,
      child: TextButton(
        focusNode: focusNode,
        onPressed: () {},
        child: const Text('Go'),
      ),
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
    final node = FocusNode();
    addTearDown(node.dispose);
    await pumpMx(tester, host(focusNode: node));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    expect(ring, findsOneWidget);
    final paint = tester.widget<CustomPaint>(ring);
    final painter = paint.foregroundPainter! as MxFocusRingPainter;
    expect(painter.color, MxSemanticColors.light.primaryForeground);
    expect(painter.placement, MxFocusRingPlacement.outside);
    // The ring rect is the child's rect grown by the offset and half a stroke.
    expect(painter.ringRect(const Size(100, 40)).left, -3);
    expect(painter.ringRect(const Size(100, 40)).right, 103);
  });

  testWidgets('touch highlight mode: focus paints no ring', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await pumpMx(tester, host(focusNode: node));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    expect(ring, findsNothing);
    // The ring listens to the mode: it appears once the mode turns keyboard.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.pump();
    expect(ring, findsOneWidget);
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

  testWidgets('the ring leaves when focus moves to a sibling', (tester) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          host(focusNode: first),
          TextButton(
            focusNode: second,
            onPressed: () {},
            child: const Text('Other'),
          ),
        ],
      ),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(first.hasPrimaryFocus, isTrue);
    expect(ring, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(second.hasPrimaryFocus, isTrue);
    expect(ring, findsNothing);
  });

  testWidgets('the control keeps primary focus once the ring appears', (
    tester,
  ) async {
    // No explicit FocusNode: the button's own node must survive the ring.
    await pumpMx(tester, host());
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(ring, findsOneWidget);
    expect(Focus.of(tester.element(find.text('Go'))).hasPrimaryFocus, isTrue);
  });
}

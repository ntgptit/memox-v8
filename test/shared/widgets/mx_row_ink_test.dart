import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('static: no ripple and nothing to focus', (tester) async {
    await pumpMx(
      tester,
      const MxRowInk(onTap: null, child: SizedBox(width: 200, height: 48)),
    );

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets(
    'tappable: fires, and focus draws the shared ring inside the row in primaryForeground',
    (tester) async {
      var taps = 0;
      await pumpMx(
        tester,
        MxRowInk(
          onTap: () => taps++,
          child: const SizedBox(width: 200, height: 48),
        ),
      );
      await tester.tap(find.byType(MxRowInk));
      expect(taps, 1);

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final ring = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.foregroundPainter is MxFocusRingPainter,
        ),
      );
      final painter = ring.foregroundPainter! as MxFocusRingPainter;

      expect(painter.color, MxSemanticColors.light.primaryForeground);
      expect(painter.placement, MxFocusRingPlacement.inside);
      expect(painter.radius, BorderRadius.circular(AppRadius.md));
    },
  );

  testWidgets('a semanticLabel names the row on its own node', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () {},
        semanticLabel: 'Open deck',
        child: const SizedBox(width: 200, height: 48),
      ),
    );

    expect(
      tester.getSemantics(find.byType(InkWell)),
      isSemantics(label: 'Open deck', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('disabled: 0.38, no tap, a disabled button', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () => taps++,
        isEnabled: false,
        child: const Text('Move here'),
      ),
    );
    await tester.tap(find.byType(MxRowInk), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MxRowInk),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
    expect(
      tester.getSemantics(find.text('Move here')),
      isSemantics(
        label: 'Move here',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets(
    'shouldDimWhenDisabled false blocks taps without painting opacity',
    (tester) async {
      var taps = 0;
      await pumpMx(
        tester,
        MxRowInk(
          onTap: () => taps++,
          isEnabled: false,
          shouldDimWhenDisabled: false,
          child: const SizedBox(height: 48, child: Text('Row')),
        ),
      );
      await tester.tap(find.text('Row'), warnIfMissed: false);
      expect(taps, 0);
      expect(
        find.ancestor(of: find.text('Row'), matching: find.byType(Opacity)),
        findsNothing,
      );
    },
  );

  // SW-REV-005: a row that selects on a long-press (Card list, Trash) says
  // so through the row, not through a GestureDetector bolted around it.
  testWidgets('onLongPress: a long-press runs it, and TalkBack offers it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var held = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () {},
        onLongPress: () => held++,
        child: const SizedBox(width: 200, height: 56, child: Text('Row')),
      ),
    );
    await tester.longPress(find.text('Row'));

    expect(held, 1);
    expect(
      tester.getSemantics(find.text('Row')),
      isSemantics(hasTapAction: true, hasLongPressAction: true),
    );
    handle.dispose();
  });

  testWidgets('placement outside puts the ring around the row, not in it', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () {},
        placement: MxFocusRingPlacement.outside,
        child: const SizedBox(width: 200, height: 48),
      ),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter is MxFocusRingPainter,
      ),
    );

    expect(
      (ring.foregroundPainter! as MxFocusRingPainter).placement,
      MxFocusRingPlacement.outside,
    );
  });
}

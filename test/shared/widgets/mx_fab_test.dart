import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = lightColorScheme;

  Future<void> pumpFab(WidgetTester tester) => pumpMx(
    tester,
    MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () {}),
  );

  Material fabMaterial(WidgetTester tester) => tester.widget<Material>(
    find
        .descendant(of: find.byType(MxFab), matching: find.byType(Material))
        .first,
  );

  testWidgets('a square 56 primary box, radius 16, 24 onPrimary glyph', (
    tester,
  ) async {
    await pumpFab(tester);
    final material = fabMaterial(tester);

    expect(tester.getSize(find.byType(MxFab)), const Size.square(56));
    expect(material.color, scheme.primary);
    expect(
      (material.shape! as MxFocusRingBorder).base,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    expect(
      IconTheme.of(tester.element(find.byIcon(AppIcons.add))).color,
      scheme.onPrimary,
    );
    expect(tester.getSize(find.byIcon(AppIcons.add)).width, 24);
  });

  testWidgets('rests at elevation 6 and lifts to 8 under a mouse', (
    tester,
  ) async {
    await pumpFab(tester);
    expect(fabMaterial(tester).elevation, 6);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(MxFab)));
    await tester.pumpAndSettle();

    expect(fabMaterial(tester).elevation, 8);
  });

  testWidgets('state layers are onPrimary at hover 8%, focus 10%, press 10%', (
    tester,
  ) async {
    await pumpFab(tester);
    final ink = tester.widget<InkWell>(
      find.descendant(of: find.byType(MxFab), matching: find.byType(InkWell)),
    );

    expect(ink.hoverColor, scheme.onPrimary.withValues(alpha: 0.08));
    expect(ink.focusColor, scheme.onPrimary.withValues(alpha: 0.1));
    expect(ink.splashColor, scheme.onPrimary.withValues(alpha: 0.1));
  });

  testWidgets('keyboard focus draws a primary ring 2 outside the box', (
    tester,
  ) async {
    await pumpFab(tester);
    expect(
      (fabMaterial(tester).shape! as MxFocusRingBorder).ring.style,
      BorderStyle.none,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final shape = fabMaterial(tester).shape! as MxFocusRingBorder;

    expect(shape.ring.color, scheme.primary);
    expect(shape.ring.width, 2);
    expect(shape.gap, 2);
    expect(
      shape.base,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  });

  testWidgets('the label is its accessible name, never painted', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxFab(
        icon: AppIcons.add,
        semanticLabel: 'New deck',
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.bySemanticsLabel('New deck'));

    expect(find.text('New deck'), findsNothing);
    expect(taps, 1);
    handle.dispose();
    await expectAccessibleTargets(tester);
  });
  // M3F-11: the SDK slot `tooltip` shows the name on hover and long-press; the
  // outer `excludeSemantics` keeps the name on one node.
  testWidgets('M3F-11: the label is also the tooltip, and one node names it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpFab(tester);

    expect(find.byTooltip('New deck'), findsOneWidget);
    expect(find.bySemanticsLabel('New deck'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip('New deck')),
      isSemantics(label: 'New deck', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('M3F-11: a long-press shows the label as the tooltip', (
    tester,
  ) async {
    await pumpFab(tester);
    expect(find.text('New deck'), findsNothing);
    await tester.longPress(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New deck'), findsOneWidget);
  });
}

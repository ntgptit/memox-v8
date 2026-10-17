import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _button = find.byType(FButton);

void main() {
  final colors = appLightColors;
  const dimens = AppDimens();

  Future<void> pumpFab(WidgetTester tester) => pumpMx(
    tester,
    MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () {}),
  );

  testWidgets("a square sizeFab ForUI primary icon button, in ForUI's "
      'primary foreground', (tester) async {
    await pumpFab(tester);

    expect(tester.getSize(find.byType(MxFab)), Size.square(dimens.sizeFab));
    expect(paintedDecoration(tester, _button).color, colors.primary);
    expect(
      iconColor(tester, find.byIcon(AppIcons.add)),
      colors.primaryForeground,
    );
    expect(
      tester.getSize(find.byIcon(AppIcons.add)).width,
      forUiTheme(
        tester,
        _button,
      ).buttonStyles.primary.lg.iconContentStyle.iconStyle.resolve({}).size,
    );
  });

  testWidgets("rests on ForUI's shadow, lifting it over the scroll", (
    tester,
  ) async {
    await pumpFab(tester);
    final shadow = forUiTheme(tester, _button).style.shadow;

    expect(shadow, isNotEmpty);
    expect(paintedDecoration(tester, _button).shadows, shadow);
  });

  testWidgets('the hover state layer is the primary hover colour', (
    tester,
  ) async {
    await pumpFab(tester);
    final resting = paintedDecoration(tester, _button).color;

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(MxFab)));
    await tester.pumpAndSettle();

    expect(
      paintedDecoration(tester, _button).color,
      colors.hover(colors.primary),
    );
    expect(resting, colors.primary);
    // The tooltip a hover brings comes and goes.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets("keyboard focus draws ForUI's focus outline round the box", (
    tester,
  ) async {
    await pumpFab(tester);
    useKeyboardFocusHighlight();
    final outline = forUiTheme(tester, _button).style.focusedOutlineStyle;
    final ring = find.descendant(
      of: _button,
      matching: find.byType(FFocusedOutline),
    );
    expect(
      tester.renderObject(ring.first),
      isNot(paintsFocusRing(outline.color, width: outline.width)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(
      focusRingRender(tester),
      paintsFocusRing(outline.color, width: outline.width),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();

    expect(find.text('New deck'), findsNothing);
    expect(taps, 1);
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  // M3F-11: the label is also the long-press tooltip, and one node names it.
  testWidgets('M3F-11: the label is also the tooltip, and one node names it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpFab(tester);

    expect(find.bySemanticsLabel('New deck'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('New deck')),
      matchesSemantics(
        label: 'New deck',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('M3F-11: a long-press shows the label as the tooltip', (
    tester,
  ) async {
    await pumpFab(tester);
    expect(find.text('New deck'), findsNothing);
    await tester.longPress(_button);
    await tester.pumpAndSettle();

    expect(find.text('New deck'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}

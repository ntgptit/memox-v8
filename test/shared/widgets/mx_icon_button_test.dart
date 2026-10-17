import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/paint_clip.dart';
import '../../support/widget_harness.dart';

final _button = find.byType(FButton);

FButtonStyle _style(WidgetTester tester) =>
    forUiTheme(tester, _button).buttonStyles.ghost.lg;

void main() {
  const dimens = AppDimens();

  testWidgets('a round sizeControl box with a sizeIcon glyph', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.more,
        semanticLabel: 'More',
        onPressed: () {},
      ),
    );

    expect(paintedRect(tester, _button).size, Size.square(dimens.sizeControl));
    expect(
      tester.getSize(find.byIcon(AppIcons.more)),
      Size.square(dimens.sizeIcon),
    );
    expect(
      tester.getSize(_button).height,
      greaterThanOrEqualTo(dimens.sizeControl),
    );
    expect(
      tester.getSize(_button).width,
      greaterThanOrEqualTo(dimens.sizeControl),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('the glyph is in the ghost icon colour on no fill', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.search,
        semanticLabel: 'Search',
        onPressed: () {},
      ),
    );

    expect(
      iconColor(tester, find.byIcon(AppIcons.search)),
      _style(tester).iconContentStyle.iconStyle.resolve({}).color,
    );
    expect(paintedDecoration(tester, _button).color, isNull);
  });

  testWidgets('the semantic label names the control on one node that keeps '
      'the tap and the long press, and a tap fires', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: () => taps++,
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Close'));

    // The tooltip's long press is merged into the labelled node.
    expect(
      node,
      matchesSemantics(
        label: 'Close',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('a long press shows the label as a tooltip', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: () {},
      ),
    );
    expect(find.text('Close'), findsNothing);

    await tester.longPress(_button);
    await tester.pumpAndSettle();

    expect(find.text('Close'), findsOneWidget);
    // The tooltip hides itself after a while.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('disabled takes the ForUI disabled glyph and ignores taps', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: null,
      ),
    );
    final resting = _style(tester).iconContentStyle.iconStyle.resolve({});
    final disabled = _style(tester).iconContentStyle.iconStyle
        .resolve({FTappableVariant.disabled});

    expect(disabled.color, isNot(resting.color));
    expect(iconColor(tester, find.byIcon(AppIcons.close)), disabled.color);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Close')),
      matchesSemantics(
        label: 'Close',
        isButton: true,
        hasEnabledState: true,
        hasSelectedState: true,
        hasLongPressAction: true,
      ),
    );
    handle.dispose();
  });

  // M3F-07: the ring is drawn outside the circle, not flush with its edge.
  testWidgets("M3F-07: a focused icon button draws ForUI's focus outline "
      'offset round it', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: () {},
      ),
    );
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
    expect(outline.spacing, greaterThan(0));
    // Focus shows the tooltip after its delay; let it come and go.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('M3F-07: the offset ring is not clipped in an app bar or a row', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      Scaffold(
        body: Column(
          children: [
            MxAppBar(
              title: 'Title',
              leading: MxIconButton(
                icon: AppIcons.close,
                semanticLabel: 'Close',
                onPressed: () {},
              ),
              actions: [
                MxIconButton(
                  icon: AppIcons.more,
                  semanticLabel: 'More',
                  onPressed: () {},
                ),
              ],
            ),
            MxListRow(
              title: 'Row',
              trailing: MxIconButton(
                icon: AppIcons.more,
                semanticLabel: 'Row more',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
    final outline = forUiTheme(tester, _button.first).style.focusedOutlineStyle;
    final reach = outline.spacing + outline.width;
    for (var i = 0; i < 3; i++) {
      final painted = _button.at(i);
      expect(
        clipsAway(tester, painted, tester.getRect(painted).inflate(reach)),
        isFalse,
        reason: 'icon button $i',
      );
    }
  });
}

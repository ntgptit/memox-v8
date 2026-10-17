import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../support/paint_clip.dart';
import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(IconButton),
  matching: find.byType(Material),
);

void main() {
  testWidgets('a round sizeControl box with a sizeIcon glyph', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.more,
        semanticLabel: 'More',
        onPressed: () {},
      ),
    );

    const dimens = AppDimens();
    expect(tester.getSize(_painted.first), Size.square(dimens.sizeControl));
    expect(
      tester.getSize(find.byIcon(AppIcons.more)),
      Size.square(dimens.sizeIcon),
    );
    expect(
      tester.getSize(find.byType(IconButton)).height,
      greaterThanOrEqualTo(dimens.sizeControl),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('the glyph is onSurface on no fill', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.search,
        semanticLabel: 'Search',
        onPressed: () {},
      ),
    );
    final glyph = tester.element(find.byIcon(AppIcons.search));

    expect(IconTheme.of(glyph).color, lightColorScheme.onSurface);
    expect(tester.widget<Material>(_painted.first).color?.a ?? 0, 0);
  });

  testWidgets('the semantic label names the control and a tap fires', (
    tester,
  ) async {
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
    // IconButton exposes the name as its semantics tooltip, which TalkBack
    // reads as the control's name.
    expect(
      tester.getSemantics(find.byType(IconButton)),
      isSemantics(tooltip: 'Close', isButton: true),
    );
    await tester.tap(find.byTooltip('Close'));

    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('disabled follows the disabled opacity', (tester) async {
    await pumpMx(
      tester,
      const MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: null,
      ),
    );
    final context = tester.element(find.byIcon(AppIcons.close));

    expect(
      IconTheme.of(context).color,
      context.colors.foreground.withValues(
        alpha: context.colors.disabledOpacity,
      ),
    );
  });

  // M3F-07: the ring was the circle's own 2px edge (`side`), flush with the
  // container; the buttons draw it `strokeFocusGap` outside.
  testWidgets('M3F-07: a focused icon button draws its ring offset', (
    tester,
  ) async {
    const dimens = AppDimens();
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: () {},
      ),
    );
    RenderBox painter() => tester.renderObject<RenderBox>(
      find
          .descendant(of: _painted.first, matching: find.byType(CustomPaint))
          .first,
    );
    bool isRing(Symbol name, List<dynamic> arguments) =>
        name == #drawPath &&
        (arguments[1] as Paint).color.toARGB32() ==
            lightColorScheme.primary.toARGB32() &&
        (arguments[1] as Paint).style == PaintingStyle.stroke;

    expect(painter(), isNot(paints..something(isRing)));

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    // The ring's centre line: the gap and half the stroke outside the circle.
    final ringCentre = (Offset.zero & painter().size).inflate(
      dimens.strokeFocusGap + dimens.strokeFocus / 2,
    );
    expect(
      painter(),
      paints..something((name, arguments) {
        if (!isRing(name, arguments)) return false;
        final bounds = (arguments[0] as Path).getBounds();
        return (arguments[1] as Paint).strokeWidth == dimens.strokeFocus &&
            (bounds.left - ringCentre.left).abs() < 0.01 &&
            (bounds.top - ringCentre.top).abs() < 0.01 &&
            (bounds.right - ringCentre.right).abs() < 0.01 &&
            (bounds.bottom - ringCentre.bottom).abs() < 0.01;
      }),
    );
  });

  testWidgets('M3F-07: the offset ring is not clipped in an app bar or a row', (
    tester,
  ) async {
    const dimens = AppDimens();
    final reach = dimens.strokeFocusGap + dimens.strokeFocus;
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
    for (var i = 0; i < 3; i++) {
      final painted = find
          .descendant(
            of: find.byType(IconButton).at(i),
            matching: find.byType(Material),
          )
          .first;
      expect(
        clipsAway(tester, painted, tester.getRect(painted).inflate(reach)),
        isFalse,
        reason: 'icon button $i',
      );
    }
  });
}

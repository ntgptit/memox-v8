import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/widget_harness.dart';

List<MxBreadcrumbSegment> _path(int depth, {void Function(int)? onTap}) => [
  for (var i = 1; i <= depth; i++)
    MxBreadcrumbSegment(label: 'Level $i', onTap: () => onTap?.call(i)),
];

void main() {
  final scheme = lightColorScheme;

  testWidgets('ancestors are tappable, the current level is not', (
    tester,
  ) async {
    final tapped = <int>[];
    await pumpMx(tester, MxBreadcrumb(segments: _path(3, onTap: tapped.add)));
    await tester.tap(find.text('Level 1'));
    await tester.tap(find.text('Level 3'), warnIfMissed: false);

    expect(tapped, [1]);
  });

  testWidgets(
    'ancestor labelMedium onSurfaceVariant, current titleSmall onSurface',
    (tester) async {
      await pumpMx(tester, MxBreadcrumb(segments: _path(2)));

      final ancestor = tester.widget<Text>(find.text('Level 1')).style!;
      final current = tester.widget<Text>(find.text('Level 2')).style!;
      final texts = tester.element(find.text('Level 1')).texts;
      expect(ancestor.fontWeight, texts.label.fontWeight);
      expect(ancestor.color, scheme.onSurfaceVariant);
      expect(current.fontWeight, texts.itemTitle.fontWeight);
      expect(current.color, scheme.onSurface);
    },
  );

  testWidgets('one outline chevron at 16 between each pair', (tester) async {
    await pumpMx(tester, MxBreadcrumb(segments: _path(4)));
    final chevrons = find.byIcon(AppIcons.chevronRight);

    expect(chevrons, findsNWidgets(3));
    expect(tester.widget<Icon>(chevrons.first).color, scheme.outline);
    expect(tester.getSize(chevrons.first).width, 16);
  });

  testWidgets('a short path starts at the 16 gutter', (tester) async {
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxBreadcrumb(segments: _path(2))),
    );
    final offset =
        tester.getTopLeft(find.text('Level 1')).dx -
        tester.getTopLeft(find.byType(MxBreadcrumb)).dx;

    expect(offset, greaterThanOrEqualTo(16));
    expect(offset, lessThan(40));
  });

  testWidgets('a 10-level path shows the current level without scrolling', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxBreadcrumb(segments: _path(10))),
    );

    expect(tester.getRect(find.text('Level 10')).right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ancestor segments are 48×48 labelled targets (R4)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxBreadcrumb(
        segments: [
          MxBreadcrumbSegment(label: 'A', onTap: () {}),
          const MxBreadcrumbSegment(label: 'B'),
        ],
      ),
    );

    await expectAccessibleTargets(tester);
  });

  testWidgets('a deep path fades its start edge and keeps its hidden '
      'ancestors reachable (DEV-306)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxBreadcrumb(segments: _path(10))),
    );
    await tester.pump();

    expect(find.byKey(MxScrollFade.leadingKey), findsOneWidget);
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
    expect(
      tester.getSemantics(find.text('Level 1', skipOffstage: false)),
      isSemantics(label: 'Level 1', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  // M3F-05: an ancestor was a bare InkWell, so keyboard focus showed only the
  // theme's focus layer. MxRowInk draws the shared 2px primary ring.
  for (final brightness in Brightness.values) {
    final focusScheme = brightness == Brightness.light
        ? lightColorScheme
        : darkColorScheme;
    testWidgets('M3F-05: a focused ancestor draws the 2px primary ring '
        '(${brightness.name})', (tester) async {
      final tapped = <int>[];
      await pumpMx(
        tester,
        MxBreadcrumb(segments: _path(3, onTap: tapped.add)),
        brightness: brightness,
      );
      useKeyboardFocusHighlight();
      expect(
        tester.renderObject(find.byType(MxBreadcrumb)),
        isNot(paintsFocusRing(focusScheme.primary)),
      );

      await tabTo(tester, find.text('Level 2'));

      expect(focusedRender(tester), paintsFocusRing(focusScheme.primary));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(tapped, [2]);
    });
  }

  testWidgets('M3F-05: the current level and a segment without a tap take '
      'no focus', (tester) async {
    await pumpMx(
      tester,
      MxBreadcrumb(
        segments: [
          const MxBreadcrumbSegment(label: 'Level 1'),
          MxBreadcrumbSegment(label: 'Level 2', onTap: () {}),
          const MxBreadcrumbSegment(label: 'Level 3'),
        ],
      ),
    );
    useKeyboardFocusHighlight();
    await tabTo(tester, find.text('Level 2'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    for (final label in ['Level 1', 'Level 3']) {
      expect(
        find.descendant(
          of: find.byElementPredicate(
            (e) => e == FocusManager.instance.primaryFocus?.context,
          ),
          matching: find.text(label),
        ),
        findsNothing,
      );
    }
  });
}

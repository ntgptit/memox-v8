import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

const _radioKey = ValueKey('mx-option-radio');
const _dimens = AppDimens();

/// The radio's painted circles: the ring first, then the indicator.
Finder _circles() => find.descendant(
  of: find.byKey(_radioKey),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle,
  ),
);

BoxDecoration _ring(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_circles().first).decoration as BoxDecoration;

Finder _dot() => _circles().last;

BoxDecoration _dotDecoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_dot()).decoration as BoxDecoration;

FRadioStyle _style(WidgetTester tester) =>
    forUiTheme(tester, find.byKey(_radioKey)).radioStyle;

void main() {
  // ForUI's radio, painted only: a ring in the muted foreground, and an
  // indicator in the primary colour that grows when selected.
  testWidgets('unselected: the ring in the muted foreground, no indicator', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
    );
    final style = _style(tester);

    expect(
      (_ring(tester).border! as Border).top,
      BorderSide(
        color: appLightColors.mutedForeground,
        width: style.borderWidth,
      ),
    );
    expect(tester.getSize(_dot()), Size.zero);
  });

  testWidgets('selected: the same ring and an indicator, in the primary '
      'colour', (tester) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}),
    );
    await tester.pumpAndSettle();
    final style = _style(tester);

    expect(
      (_ring(tester).border! as Border).top.color,
      appLightColors.mutedForeground,
    );
    expect(_dotDecoration(tester).color, appLightColors.primary);
    expect(_dotDecoration(tester).shape, BoxShape.circle);
    expect(tester.getSize(_dot()), Size.square(style.indicatorSize));
    expect(tester.getCenter(_dot()), tester.getCenter(_circles().first));
  });

  testWidgets('dark: the selected indicator is the primary, the ring muted', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}),
      brightness: Brightness.dark,
    );
    await tester.pumpAndSettle();
    expect(_dotDecoration(tester).color, appDarkColors.primary);

    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
      brightness: Brightness.dark,
    );
    expect(
      (_ring(tester).border! as Border).top.color,
      appDarkColors.mutedForeground,
    );
  });

  testWidgets('56 tall, 72 with a description; a long one grows the row', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxOptionRow(
          title: 'Eight box',
          isSelected: false,
          onSelected: () {},
        ),
      ),
    );
    final short = tester.getSize(find.byType(MxOptionRow)).height;
    expect(short, _dimens.sizeListRow);

    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxOptionRow(
          title: 'Eight box',
          description: 'Eight intervals',
          isSelected: false,
          onSelected: () {},
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxOptionRow)).height,
      _dimens.sizeListRowTwoLine,
    );

    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxOptionRow(
          title: 'Eight box',
          description:
              'Cards climb eight boxes, each a longer interval than the '
              'last, and drop back to the first when forgotten.',
          isSelected: false,
          onSelected: () {},
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxOptionRow)).height,
      greaterThan(_dimens.sizeListRowTwoLine),
    );
  });

  testWidgets('a tap selects; announced as a checked exclusive option', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () => taps++),
    );
    await tester.tap(find.byType(MxOptionRow));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel('SM-2')),
      isSemantics(
        label: 'SM-2',
        isChecked: true,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasSelectedState: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the row is a 48 target', (tester) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
    );

    expect(
      tester.getSize(find.byType(MxOptionRow)).height,
      greaterThanOrEqualTo(_dimens.sizeControl),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('disabled at the theme disabled opacity', (tester) async {
    await pumpMx(
      tester,
      const MxOptionRow(title: 'A', isSelected: false, onSelected: null),
    );
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byKey(_radioKey),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      appLightColors.disabledOpacity,
    );
  });

  testWidgets('a row not selectable yet can keep full contrast: isDimmed '
      'false (FE-A6 spec §3)', (tester) async {
    await pumpMx(
      tester,
      const MxOptionRow(
        title: 'Recall',
        isSelected: false,
        onSelected: null,
        isDimmed: false,
      ),
    );

    expect(
      find.ancestor(of: find.text('Recall'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('a selected row that cannot change is not dimmed (critique '
      '2026-09-30: the locked algorithm)', (tester) async {
    await pumpMx(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: true, onSelected: null),
    );
    expect(
      find.ancestor(of: find.text('SM-2'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('a dimmed row keeps its description at full strength', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxOptionRow(
        title: 'Guess',
        description: 'Needs five different meanings',
        isSelected: false,
        onSelected: null,
      ),
    );
    expect(
      find.ancestor(of: find.text('Guess'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Needs five different meanings'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  // SW-REV-006: a row that cannot be picked is announced as disabled.
  testWidgets('a row that cannot be picked is a disabled radio to TalkBack', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: false, onSelected: null),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('SM-2')),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('M3F-17: a row that cannot be picked blocks its trailing '
      'control and keeps the choice dimming rules', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxOptionRow(
        title: 'SM-2',
        isSelected: false,
        onSelected: null,
        trailing: MxButton(label: 'Info', onPressed: () => taps++),
      ),
    );
    await tester.tap(find.text('Info'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(
      find.ancestor(of: find.text('SM-2'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
  });

  // M3F-05: the row draws ForUI's focus outline for a keyboard user
  // (MxRowInk).
  for (final brightness in Brightness.values) {
    final focusColors = brightness == Brightness.light
        ? appLightColors
        : appDarkColors;
    testWidgets('M3F-05: a focused row draws the primary focus outline '
        '(${brightness.name})', (tester) async {
      var taps = 0;
      await pumpMx(
        tester,
        MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () => taps++),
        brightness: brightness,
      );
      useKeyboardFocusHighlight();
      final outline = forUiTheme(
        tester,
        find.byType(MxOptionRow),
      ).style.focusedOutlineStyle;
      expect(outline.color, focusColors.primary);
      expect(
        tester.renderObject(find.byType(MxOptionRow)),
        isNot(paintsFocusRing(outline.color, width: outline.width)),
      );

      await tabTo(tester, find.text('SM-2'));

      expect(
        focusRingRender(tester),
        paintsFocusRing(outline.color, width: outline.width),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  }

  /// Whether the node holding primary focus sits inside the row.
  bool focusIsInRow(WidgetTester tester) {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    return find
        .descendant(
          of: find.byType(MxOptionRow),
          matching: find.byElementPredicate((e) => e == focused),
        )
        .evaluate()
        .isNotEmpty;
  }

  testWidgets('M3F-05: a row that cannot be picked takes no focus', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: false, onSelected: null),
    );
    useKeyboardFocusHighlight();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(focusIsInRow(tester), isFalse);
  });

  testWidgets('the whole row is one tab stop: the painted radio takes no '
      'focus of its own', (tester) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
    );
    useKeyboardFocusHighlight();
    final stops = <Rect>{};
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      if (focusIsInRow(tester)) {
        stops.add(
          tester.getRect(
            find.byElementPredicate(
              (e) => e == FocusManager.instance.primaryFocus!.context,
            ),
          ),
        );
      }
    }

    expect(stops, hasLength(1));
  });
}

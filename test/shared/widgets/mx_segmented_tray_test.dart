import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

enum _Range { week, month }

const _segments = [
  MxSegment(value: _Range.week, label: '7d'),
  MxSegment(value: _Range.month, label: '30d'),
];

const _long = [
  MxSegment(value: _Range.week, label: 'Every day of the week'),
  MxSegment(value: _Range.month, label: 'Every day of the month'),
];

const _dimens = AppDimens();

/// The option labelled [label]: its tappable.
Finder _segment(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(FTappable)).first;

Finder _check(String label) =>
    find.descendant(of: _segment(label), matching: find.byIcon(AppIcons.check));

Finder _tray() => find.byType(MxSegmentedTray<_Range>);

/// The fill the option paints behind its label, if any.
Color? _fill(WidgetTester tester, String label) {
  final boxes = find.descendant(
    of: _segment(label),
    matching: find.byType(DecoratedBox),
  );
  for (final box in boxes.evaluate()) {
    final decoration = (box.widget as DecoratedBox).decoration;
    if (decoration is BoxDecoration && decoration.borderRadius != null) {
      return decoration.color;
    }
  }
  return null;
}

Widget _trayWidget({
  _Range? selected = _Range.week,
  ValueChanged<_Range>? onSelected,
  List<MxSegment<_Range>> segments = _segments,
  bool isWide = false,
}) => MxSegmentedTray<_Range>(
  segments: segments,
  selected: selected,
  onSelected: onSelected,
  isWide: isWide,
);

void main() {
  for (final brightness in Brightness.values) {
    final colors = brightness == Brightness.light
        ? appLightColors
        : appDarkColors;

    testWidgets('the chosen option is raised on the background with a check '
        'and the foreground label; the rest are bare, muted '
        '(${brightness.name})', (tester) async {
      await pumpMx(
        tester,
        _trayWidget(onSelected: (_) {}),
        brightness: brightness,
      );

      expect(_check('7d'), findsOneWidget);
      expect(_check('30d'), findsNothing);
      expect(textColor(tester, find.text('7d')), colors.foreground);
      expect(textColor(tester, find.text('30d')), colors.mutedForeground);
      expect(iconColor(tester, find.byIcon(AppIcons.check)), colors.foreground);
      expect(
        tester.getSize(find.byIcon(AppIcons.check)).width,
        _dimens.sizeIconInline,
      );
      expect(_fill(tester, '7d'), colors.background);
      expect(_fill(tester, '30d'), isNull);
    });

    testWidgets('the tray sits on the muted ground (${brightness.name})', (
      tester,
    ) async {
      await pumpMx(
        tester,
        _trayWidget(onSelected: (_) {}),
        brightness: brightness,
      );
      final ground = tester.widget<DecoratedBox>(
        find.descendant(of: _tray(), matching: find.byType(DecoratedBox)).first,
      );

      expect((ground.decoration as BoxDecoration).color, colors.muted);
    });

    testWidgets('a disabled tray dims its labels and fills nothing but the '
        'chosen option (${brightness.name})', (tester) async {
      await pumpMx(tester, _trayWidget(), brightness: brightness);

      expect(
        textColor(tester, find.text('7d')),
        colors.disable(colors.mutedForeground),
      );
      expect(
        textColor(tester, find.text('30d')),
        colors.disable(colors.mutedForeground),
      );
      expect(_fill(tester, '30d'), isNull);
    });
  }

  testWidgets('a null selection draws no check: a choice still to make', (
    tester,
  ) async {
    _Range? picked;
    await pumpMx(
      tester,
      _trayWidget(selected: null, onSelected: (v) => picked = v),
    );

    expect(find.byIcon(AppIcons.check), findsNothing);
    await tester.tap(find.text('30d'));
    await tester.pumpAndSettle();
    expect(picked, _Range.month);
  });

  testWidgets('a tap reports the option; every option is a 48 target', (
    tester,
  ) async {
    _Range? picked;
    await pumpMx(tester, _trayWidget(onSelected: (v) => picked = v));
    await tester.tap(find.text('30d'));
    await tester.pumpAndSettle();

    expect(picked, _Range.month);
    for (final label in ['7d', '30d']) {
      expect(
        tester.getSize(_segment(label)).height,
        greaterThanOrEqualTo(_dimens.sizeControl),
        reason: label,
      );
    }
    // The tray hugs its options by the 4 inset on each side.
    expect(
      tester.getSize(_tray()).height,
      tester.getSize(_segment('7d')).height + 2 * _dimens.space4,
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('tapping the chosen option reports it again', (tester) async {
    final picked = <_Range>[];
    await pumpMx(tester, _trayWidget(onSelected: picked.add));
    await tester.tap(find.text('7d'));
    await tester.pumpAndSettle();

    expect(picked, [_Range.week]);
  });

  testWidgets('the options split the tray evenly with a 4 gap', (tester) async {
    await pumpMx(tester, _trayWidget(onSelected: (_) {}));
    final first = tester.getRect(_segment('7d'));
    final second = tester.getRect(_segment('30d'));
    final tray = tester.getRect(_tray());

    expect(first.width, second.width);
    expect(second.left - first.right, _dimens.space4);
    expect(first.left - tray.left, _dimens.space4);
    expect(tray.right - second.right, _dimens.space4);
  });

  testWidgets('announced as a selected exclusive option', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _trayWidget(onSelected: (_) {}));

    expect(
      tester.getSemantics(find.bySemanticsLabel('7d')),
      matchesSemantics(
        label: '7d',
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('30d')),
      matchesSemantics(
        label: '30d',
        isSelected: false,
        hasSelectedState: true,
        isButton: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  test('two or three options only', () {
    expect(
      () => MxSegmentedTray(
        segments: const [MxSegment(value: 1, label: 'a')],
        selected: 1,
        onSelected: (_) {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('a null onSelected disables every option: no tap, and it says '
      'so', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _trayWidget());

    expect(
      tester.getSemantics(find.bySemanticsLabel('30d')),
      matchesSemantics(
        label: '30d',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    await tester.tap(find.text('30d'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('a long label stacks the options, one per 48 tall line', (
    tester,
  ) async {
    _Range? picked;
    await pumpMx(
      tester,
      _trayWidget(onSelected: (v) => picked = v, segments: _long),
    );
    final week = tester.getRect(_segment('Every day of the week'));
    final month = tester.getRect(_segment('Every day of the month'));

    expect(week.height, greaterThanOrEqualTo(_dimens.sizeControl));
    expect(week.left, month.left);
    expect(week.width, month.width);
    expect(month.top - week.bottom, _dimens.space4);
    await tester.tap(find.text('Every day of the month'));
    await tester.pumpAndSettle();
    expect(picked, _Range.month);
    await expectAccessibleTargets(tester);
  });

  testWidgets('isWide widens the option padding to 16', (tester) async {
    await pumpMx(tester, _trayWidget(onSelected: (_) {}));
    final narrow = tester.getSize(_tray()).width;

    await pumpMx(tester, _trayWidget(onSelected: (_) {}, isWide: true));
    final wide = tester.getSize(_tray()).width;

    // 12 to 16 on both sides of each of the two options.
    expect(wide - narrow, 2 * 2 * (_dimens.space16 - _dimens.space12));
  });

  testWidgets('short labels stay on one line, also with the check', (
    tester,
  ) async {
    await pumpMx(tester, _trayWidget(onSelected: (_) {}));
    expect(
      tester.getTopLeft(_segment('7d')).dy,
      tester.getTopLeft(_segment('30d')).dy,
    );

    await pumpMx(
      tester,
      _trayWidget(selected: _Range.month, onSelected: (_) {}),
    );
    expect(
      tester.getTopLeft(_segment('7d')).dy,
      tester.getTopLeft(_segment('30d')).dy,
    );
  });

  testWidgets("keyboard focus draws ForUI's focus outline round the focused "
      'option', (tester) async {
    await pumpMx(tester, _trayWidget(onSelected: (_) {}));
    useKeyboardFocusHighlight();
    final outline = forUiTheme(tester, _tray()).style.focusedOutlineStyle;
    final ring = find.descendant(
      of: _segment('7d'),
      matching: find.byType(FFocusedOutline),
    );
    expect(
      tester.renderObject(ring),
      isNot(paintsFocusRing(outline.color, width: outline.width)),
    );

    await tabTo(tester, find.text('7d'));

    expect(
      tester.renderObject(ring),
      paintsFocusRing(outline.color, width: outline.width),
    );
  });
}

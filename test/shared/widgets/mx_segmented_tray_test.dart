import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

import '../../support/widget_harness.dart';

enum _Range { week, month }

const _segments = [
  MxSegment(value: _Range.week, label: '7d'),
  MxSegment(value: _Range.month, label: '30d'),
];

const _dimens = AppDimens();

Finder _segment(String label) => find.widgetWithText(TextButton, label);

Color? _labelColor(WidgetTester tester, String label) =>
    DefaultTextStyle.of(tester.element(find.text(label))).style.color;

Finder _check(String label) =>
    find.descendant(of: _segment(label), matching: find.byIcon(AppIcons.check));

SegmentedButton<_Range> _button(WidgetTester tester) => tester
    .widget<SegmentedButton<_Range>>(find.byType(SegmentedButton<_Range>));

Widget _tray({
  _Range? selected = _Range.week,
  ValueChanged<_Range>? onSelected,
  List<MxSegment<_Range>> segments = _segments,
}) => MxSegmentedTray<_Range>(
  segments: segments,
  selected: selected,
  onSelected: onSelected,
);

void main() {
  final scheme = lightColorScheme;

  testWidgets('the chosen option shows a check and the accent label, no fill', (
    tester,
  ) async {
    await pumpMx(tester, _tray(onSelected: (_) {}));

    expect(_check('7d'), findsOneWidget);
    expect(_check('30d'), findsNothing);
    expect(_labelColor(tester, '7d'), scheme.primary);
    expect(_labelColor(tester, '30d'), scheme.onSurface);
    expect(tester.getSize(_check('7d')).width, _dimens.sizeIconButton);
  });

  // What the segment paints, not what the theme declares: a slot left null
  // falls back to the SDK default, which fills the chosen segment with
  // secondaryContainer (tokens: never a button background).
  Color? paintedFill(WidgetTester tester, String label) => tester
      .widget<Material>(
        find
            .descendant(of: _segment(label), matching: find.byType(Material))
            .first,
      )
      .color;

  bool isUnfilled(Color? color) => color == null || color.a == 0;

  for (final brightness in Brightness.values) {
    testWidgets(
      'no segment paints a fill, chosen or not (${brightness.name})',
      (tester) async {
        await pumpMx(tester, _tray(onSelected: (_) {}), brightness: brightness);

        final scheme = brightness == Brightness.light
            ? lightColorScheme
            : darkColorScheme;
        expect(paintedFill(tester, '7d'), isNot(scheme.secondaryContainer));
        expect(isUnfilled(paintedFill(tester, '7d')), isTrue);
        expect(isUnfilled(paintedFill(tester, '30d')), isTrue);
      },
    );

    testWidgets('a disabled tray paints no fill either (${brightness.name})', (
      tester,
    ) async {
      await pumpMx(tester, _tray(), brightness: brightness);

      expect(isUnfilled(paintedFill(tester, '7d')), isTrue);
      expect(isUnfilled(paintedFill(tester, '30d')), isTrue);
    });

    testWidgets('the stacked tray paints no fill (${brightness.name})', (
      tester,
    ) async {
      await pumpMx(
        tester,
        _tray(
          onSelected: (_) {},
          segments: const [
            MxSegment(value: _Range.week, label: 'Every day of the week'),
            MxSegment(value: _Range.month, label: 'Every day of the month'),
          ],
        ),
        brightness: brightness,
      );

      expect(isUnfilled(paintedFill(tester, 'Every day of the week')), isTrue);
      expect(isUnfilled(paintedFill(tester, 'Every day of the month')), isTrue);
    });
  }

  testWidgets('a null selection draws no check: a choice still to make', (
    tester,
  ) async {
    _Range? picked;
    await pumpMx(tester, _tray(selected: null, onSelected: (v) => picked = v));

    expect(find.byIcon(AppIcons.check), findsNothing);
    await tester.tap(find.text('30d'));
    expect(picked, _Range.month);
  });

  testWidgets('a tap reports the option; 40 tall in a 48 target band', (
    tester,
  ) async {
    _Range? picked;
    await pumpMx(tester, _tray(onSelected: (v) => picked = v));
    await tester.tap(find.text('30d'));

    expect(picked, _Range.month);
    final size = tester.getSize(find.byType(MxSegmentedTray<_Range>));
    expect(size.height, 48);
    expect(tester.getSize(find.byType(TextButton).first).height, 48);
    // The edge is a stadium 40 tall, centred in the band, 1 wide inside.
    expect(
      tester.renderObject(find.byType(SegmentedButton<_Range>)),
      paints..rrect(
        rrect: RRect.fromLTRBR(
          0.5,
          4.5,
          size.width - 0.5,
          43.5,
          const Radius.circular(19.5),
        ),
        color: scheme.outline,
        strokeWidth: _dimens.strokeHairline,
      ),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('tapping the chosen option reports it again', (tester) async {
    final picked = <_Range>[];
    await pumpMx(tester, _tray(onSelected: picked.add));
    await tester.tap(find.text('7d'));

    expect(picked, [_Range.week]);
  });

  testWidgets('a 1 outline edge round and between the segments', (
    tester,
  ) async {
    await pumpMx(tester, _tray(onSelected: (_) {}));

    final theme = SegmentedButtonTheme.of(tester.element(_segment('7d')));
    final side = theme.style!.side!.resolve({});
    expect(side?.color, scheme.outline);
    expect(side?.width, _dimens.strokeHairline);
    final shape = theme.style!.shape!.resolve({});
    expect(shape, isA<MxFocusRingBorder>());
    expect((shape as MxFocusRingBorder).base, isA<StadiumBorder>());
  });

  testWidgets('announced as a selected exclusive option', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _tray(onSelected: (_) {}));

    expect(
      tester.getSemantics(find.text('7d')),
      isSemantics(
        label: '7d',
        isSelected: true,
        isButton: true,
        isInMutuallyExclusiveGroup: true,
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

  testWidgets('a null onSelected disables every option, M3 disabled colours', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _tray());

    expect(
      tester.getSemantics(find.text('30d')),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    expect(
      _labelColor(tester, '30d'),
      scheme.onSurface.withValues(alpha: _dimens.opacityDisabledContent),
    );
    final theme = SegmentedButtonTheme.of(tester.element(_segment('7d')));
    expect(
      theme.style!.side!.resolve({WidgetState.disabled})?.color,
      scheme.onSurface.withValues(alpha: _dimens.opacityDisabledContainer),
    );
    handle.dispose();
  });

  testWidgets('a long label stacks the options, one per 48 tall line', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _tray(
        onSelected: (_) {},
        segments: const [
          MxSegment(value: _Range.week, label: 'Every day of the week'),
          MxSegment(value: _Range.month, label: 'Every day of the month'),
        ],
      ),
    );

    expect(_button(tester).direction, Axis.vertical);
    expect(tester.getSize(_segment('Every day of the week')).height, 48);
    expect(
      tester.getTopLeft(_segment('Every day of the month')).dy,
      tester.getBottomLeft(_segment('Every day of the week')).dy,
    );
    await tester.tap(find.text('Every day of the month'));
  });

  testWidgets('isWide widens the option padding to 16', (tester) async {
    await pumpMx(
      tester,
      MxSegmentedTray<_Range>(
        segments: _segments,
        selected: _Range.week,
        onSelected: (_) {},
        isWide: true,
      ),
    );

    expect(
      _button(tester).style?.padding?.resolve({}),
      EdgeInsets.symmetric(horizontal: _dimens.space16),
    );
  });

  testWidgets('short labels stay on one line, also with the check', (
    tester,
  ) async {
    await pumpMx(tester, _tray(onSelected: (_) {}));
    expect(_button(tester).direction, Axis.horizontal);

    await pumpMx(tester, _tray(selected: _Range.month, onSelected: (_) {}));
    expect(_button(tester).direction, Axis.horizontal);
  });

  testWidgets('keyboard focus draws the offset ring round the control', (
    tester,
  ) async {
    await pumpMx(tester, _tray(onSelected: (_) {}));
    final box = tester.renderObject(find.byType(SegmentedButton<_Range>));

    bool isRing(Symbol method, List<dynamic> arguments) =>
        method == #drawPath &&
        // A canvas paint keeps the colour as 8-bit channels.
        (arguments[1] as Paint).color.toARGB32() == scheme.primary.toARGB32() &&
        (arguments[1] as Paint).strokeWidth == _dimens.strokeFocus;

    expect(box, isNot(paints..something(isRing)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(box, paints..something(isRing));
  });
}

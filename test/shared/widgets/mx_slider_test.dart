import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

// Spec §13.8, DSD-23: ForUI's slider under the theme's slider style.
void main() {
  final colors = appLightColors;
  Finder slider() => find.byType(FSlider);

  /// What TalkBack reads as the slider's value, in seconds.
  String valueOf(WidgetTester tester) =>
      tester.getSemantics(find.byType(MxSlider)).getSemanticsData().value;

  Widget seek({
    double value = 3000,
    double max = 10000,
    ValueChanged<double>? onChanged,
    ValueChanged<double>? onChangeEnd,
  }) => SizedBox(
    width: 300,
    child: MxSlider(
      value: value,
      max: max,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      semanticLabel: 'Audio position',
      semanticFormatter: (value) => '${(value / 1000).round()}s',
    ),
  );

  testWidgets('is a ForUI slider read from the theme, one unit with max', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, seek(onChanged: (_) {}));

    expect(slider(), findsOneWidget);
    // Without a formatter the value is read as a share of the track.
    final bare = tester.getSemantics(find.byType(MxSlider));
    expect(bare.getSemanticsData().value, isNotEmpty);
    final style = forUiTheme(tester, slider()).sliderStyles.horizontal;
    expect(style.activeColor.resolve({}), colors.primary);
    // The track after the thumb takes `mutedForeground`, not the theme's
    // `secondary`, which equals the `muted` pane the TOPIK player sits on;
    // the played part is the accent fill. Both hold 3:1 on `muted` in both
    // modes (audit 2026-10-19, G2; follow-ups spec S1).
    final applied = tester.widget<FSlider>(slider()).style(style);
    expect(applied.activeColor.resolve({}), MxStatusColors.light.accentFill);
    expect(applied.inactiveColor.resolve({}), colors.mutedForeground);
    expect(colors.secondary, colors.muted);
    // ForUI's disabled dimming stays: only the base is replaced.
    expect(
      applied.activeColor.resolve({FTappableVariant.disabled}),
      isNot(MxStatusColors.light.accentFill),
    );
    handle.dispose();

    // In dark the accent fill is not the primary: the override is real.
    await pumpMx(tester, seek(onChanged: (_) {}), brightness: Brightness.dark);
    // Past ForUI's theme easing.
    await tester.pumpAndSettle();
    final dark = tester
        .widget<FSlider>(slider())
        .style(forUiTheme(tester, slider()).sliderStyles.horizontal);
    expect(dark.activeColor.resolve({}), MxStatusColors.dark.accentFill);
  });

  testWidgets('semanticFormatter: TalkBack reads the value in the '
      "caller's unit", (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, seek(onChanged: (_) {}));

    expect(valueOf(tester), '3s');
    handle.dispose();
  });

  testWidgets('drags report the new value and its end', (tester) async {
    final value = ValueNotifier<double>(0);
    addTearDown(value.dispose);
    double? changed;
    double? ended;
    await pumpMx(
      tester,
      ValueListenableBuilder(
        valueListenable: value,
        builder: (_, current, _) => seek(
          value: current,
          onChanged: (next) {
            changed = next;
            value.value = next;
          },
          onChangeEnd: (next) => ended = next,
        ),
      ),
    );
    final rect = tester.getRect(slider());
    final drag = await tester.startGesture(
      Offset(rect.left + 8, rect.center.dy),
    );
    for (var i = 0; i < 10; i++) {
      await drag.moveBy(const Offset(15, 0));
      await tester.pump();
    }
    await drag.up();
    await tester.pumpAndSettle();

    expect(changed, greaterThan(0));
    expect(changed, lessThanOrEqualTo(10000));
    expect(ended, changed);
  });

  group('the tooltip over the thumb while dragging', () {
    Future<(Finder, double Function())> dragThumb(
      WidgetTester tester, {
      required bool isFormatted,
    }) async {
      final value = ValueNotifier<double>(0);
      addTearDown(value.dispose);
      await pumpMx(
        tester,
        ValueListenableBuilder(
          valueListenable: value,
          builder: (_, current, _) => SizedBox(
            width: 300,
            child: MxSlider(
              value: current,
              max: 10000,
              onChanged: (next) => value.value = next,
              semanticLabel: 'Audio position',
              semanticFormatter: isFormatted
                  ? (value) => '${(value / 1000).round()}s'
                  : null,
            ),
          ),
        ),
      );
      final rect = tester.getRect(slider());
      final drag = await tester.startGesture(
        Offset(rect.left + 8, rect.center.dy),
      );
      await drag.moveBy(const Offset(40, 0));
      await drag.moveBy(const Offset(60, 0));
      await tester.pump(const Duration(milliseconds: 300));
      addTearDown(() => drag.up());
      return (slider(), () => value.value);
    }

    testWidgets("speaks the caller's unit, as the semantics do", (
      tester,
    ) async {
      final (_, value) = await dragThumb(tester, isFormatted: true);

      expect(value(), greaterThan(0));
      final seconds = '${(value() / 1000).round()}s';
      expect(find.text(seconds), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets("keeps ForUI's percentage when there is no formatter", (
      tester,
    ) async {
      final (_, value) = await dragThumb(tester, isFormatted: false);

      expect(value(), greaterThan(0));
      expect(
        find.text('${(value() / 10000 * 100).toStringAsFixed(0)}%'),
        findsOneWidget,
      );
    });
  });

  testWidgets('a tap on the track reports a value along it', (tester) async {
    double? changed;
    await pumpMx(tester, seek(value: 0, onChanged: (v) => changed = v));
    final rect = tester.getRect(slider());
    await tester.tapAt(Offset(rect.center.dx, rect.center.dy));
    await tester.pumpAndSettle();

    expect(changed, closeTo(5000, 1500));
  });

  testWidgets('a value past max is drawn at max', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxSlider(
          value: 12000,
          max: 10000,
          onChanged: (_) {},
          semanticLabel: 'Audio position',
        ),
      ),
    );

    expect(valueOf(tester), '100%');
    handle.dispose();
  });

  testWidgets('max 0 is a disabled slider, never an assertion', (tester) async {
    final handle = tester.ensureSemantics();
    double? changed;
    await pumpMx(
      tester,
      seek(value: 0, max: 0, onChanged: (value) => changed = value),
    );

    expect(tester.takeException(), isNull);
    expect(tester.widget<FSlider>(slider()).enabled, isFalse);
    await tester.drag(slider(), const Offset(100, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(changed, isNull);
    handle.dispose();
  });

  testWidgets('a null onChanged is a disabled slider', (tester) async {
    await pumpMx(tester, seek());

    expect(tester.widget<FSlider>(slider()).enabled, isFalse);
  });

  testWidgets("keyboard focus draws ForUI's focus outline round the handle", (
    tester,
  ) async {
    await pumpMx(tester, seek(value: 5000, onChanged: (_) {}));
    useKeyboardFocusHighlight();
    final outline = forUiTheme(
      tester,
      slider(),
    ).sliderStyles.horizontal.thumbStyle.focusedOutlineStyle;
    final ring = find.descendant(
      of: slider(),
      matching: find.byType(FFocusedOutline),
    );
    expect(
      tester.renderObject(ring.first),
      isNot(paintsFocusRing(outline.color, width: outline.width)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(
      tester.renderObject(ring.first),
      paintsFocusRing(outline.color, width: outline.width),
    );
  });

  testWidgets('arrow keys move the handle and report', (tester) async {
    final changes = <double>[];
    await pumpMx(tester, seek(value: 5000, onChanged: changes.add));
    useKeyboardFocusHighlight();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(changes, isNotEmpty);
    expect(changes.last, greaterThan(5000));
  });

  testWidgets('announced with its label and value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, seek(value: 5000, onChanged: (_) {}));
    expect(find.bySemanticsLabel('Audio position'), findsOneWidget);
    final data = tester.getSemantics(find.byType(MxSlider)).getSemanticsData();
    expect(data.label, 'Audio position');
    expect(data.flagsCollection.isSlider, isTrue);
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    expect(data.hasAction(SemanticsAction.decrease), isTrue);
    handle.dispose();
  });

  testWidgets('the handle is a 48 target', (tester) async {
    await pumpMx(tester, seek(value: 5000, onChanged: (_) {}));

    expect(
      tester.getSize(find.byType(MxSlider)).height,
      greaterThanOrEqualTo(48),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('the whole 48 target seeks: a tap above the thin track moves '
      'the value and ends the seek', (tester) async {
    final changes = <double>[];
    final ends = <double>[];
    await pumpMx(
      tester,
      seek(value: 0, onChanged: changes.add, onChangeEnd: ends.add),
    );
    final target = tester.getRect(find.byType(MxSlider));
    final thumb = tester.getRect(slider());
    // Above ForUI's own slider box, inside the target, at the track's end.
    expect(thumb.top, greaterThan(target.top));
    await tester.tapAt(Offset(target.right - 1, target.top + 1));
    await tester.pumpAndSettle();

    expect(changes.single, 10000);
    expect(ends.single, 10000);
  });
}

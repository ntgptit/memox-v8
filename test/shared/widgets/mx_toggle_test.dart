import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

Finder _switch() => find.byType(FSwitch);

FSwitchStyle _style(WidgetTester tester) =>
    forUiTheme(tester, _switch()).switchStyle;

/// What the switch paints: its one CustomPaint draws the track, the focus
/// outline and the thumb.
RenderObject _painted(WidgetTester tester) => tester.renderObject(
  find.descendant(of: _switch(), matching: find.byType(CustomPaint)).first,
);

/// A rounded rect drawn in [color]: the track or the thumb. A canvas keeps
/// the colour as 8-bit channels.
bool Function(Symbol, List<dynamic>) _rrectIn(
  Color color, {
  PaintingStyle style = PaintingStyle.fill,
}) =>
    (name, arguments) =>
        name == #drawRRect &&
        (arguments[1] as Paint).color.toARGB32() == color.toARGB32() &&
        (arguments[1] as Paint).style == style;

/// The switch's track, then its thumb, in paint order.
PaintPattern _paintsSwitch({required Color track, required Color thumb}) =>
    paints
      ..something(_rrectIn(track))
      ..something(_rrectIn(thumb));

void main() {
  const dimens = AppDimens();

  Widget toggle({
    bool isOn = false,
    ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) => MxToggle(
    isOn: isOn,
    onChanged: enabled ? (onChanged ?? (_) {}) : null,
    semanticLabel: 'Reminders',
  );

  testWidgets("is ForUI's switch, in a box at least 48 wide, holding its "
      'value and label', (tester) async {
    await pumpMx(tester, toggle());

    final switchWidget = tester.widget<FSwitch>(_switch());
    expect(switchWidget.value, isFalse);
    expect(switchWidget.enabled, isTrue);
    expect(switchWidget.semanticsLabel, 'Reminders');
    expect(
      tester.getSize(find.byType(MxToggle)).width,
      greaterThanOrEqualTo(dimens.sizeControl),
    );
    expect(
      tester.getSize(find.byType(MxToggle)).width,
      greaterThanOrEqualTo(tester.getSize(_switch()).width),
    );
  });

  testWidgets('the toggle box is 48 tall around the switch', (tester) async {
    await pumpMx(tester, toggle());

    expect(tester.getSize(find.byType(MxToggle)).height, dimens.sizeControl);
    expect(
      tester.getCenter(_switch()).dy,
      tester.getCenter(find.byType(MxToggle)).dy,
    );
  });

  for (final (name, isOn, variants) in <(String, bool, Set<FVariant>)>[
    ('off: the track and thumb of the switch style', false, <FVariant>{}),
    (
      'on: the selected track and thumb of the switch style',
      true,
      <FVariant>{FSwitchVariant.selected},
    ),
  ]) {
    testWidgets(name, (tester) async {
      await pumpMx(tester, toggle(isOn: isOn));
      final style = _style(tester);

      expect(
        _painted(tester),
        _paintsSwitch(
          track: style.trackColor.resolve(variants),
          thumb: style.thumbColor.resolve(variants),
        ),
      );
      if (!isOn) return;
      expect(
        style.trackColor.resolve(variants),
        isNot(style.trackColor.resolve(<FVariant>{})),
      );
    });
  }

  testWidgets('a tap on the switch reports the flipped value once', (
    tester,
  ) async {
    final reported = <bool>[];
    await pumpMx(tester, toggle(onChanged: reported.add));
    await tester.tap(_switch());
    await tester.pumpAndSettle();

    expect(reported, [true]);
  });

  testWidgets('a tap in the box beside the switch flips it too, once', (
    tester,
  ) async {
    final reported = <bool>[];
    await pumpMx(tester, toggle(isOn: true, onChanged: reported.add));
    final box = tester.getRect(find.byType(MxToggle));
    final inner = tester.getRect(_switch());
    // Inside the 48 box, outside the switch paint.
    expect(box.height, greaterThan(inner.height));
    await tester.tapAt(Offset(inner.center.dx, inner.top - 1));
    await tester.pumpAndSettle();

    expect(reported, [false]);
  });

  testWidgets('announced as a labelled toggle with a 48 target', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, toggle(isOn: true));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminders')),
      isSemantics(
        label: 'Reminders',
        isToggled: true,
        hasToggledState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  testWidgets("focus draws ForUI's focus colour round the track", (
    tester,
  ) async {
    await pumpMx(tester, toggle());
    useKeyboardFocusHighlight();
    final focus = _style(tester).focusColor;
    final before = tester.getRect(_switch());
    expect(
      _painted(tester),
      isNot(paints..something(_rrectIn(focus, style: PaintingStyle.stroke))),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(
      _painted(tester),
      paints..something(_rrectIn(focus, style: PaintingStyle.stroke)),
    );
    expect(tester.getRect(_switch()), before);
  });

  testWidgets('a pressed on switch keeps its thumb and track apart (M3F-15)', (
    tester,
  ) async {
    await pumpMx(tester, toggle(isOn: true));
    final style = _style(tester);
    final on = <FVariant>{FSwitchVariant.selected};
    final press = await tester.startGesture(tester.getCenter(_switch()));
    await tester.pumpAndSettle();

    expect(
      _painted(tester),
      _paintsSwitch(
        track: style.trackColor.resolve(on),
        thumb: style.thumbColor.resolve(on),
      ),
    );
    expect(style.thumbColor.resolve(on), isNot(style.trackColor.resolve(on)));
    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a focused toggle drops its ring when it is rebuilt disabled', (
    tester,
  ) async {
    final onChanged = ValueNotifier<ValueChanged<bool>?>((_) {});
    addTearDown(onChanged.dispose);
    await pumpMx(
      tester,
      ValueListenableBuilder(
        valueListenable: onChanged,
        builder: (_, callback, _) => MxToggle(
          isOn: false,
          onChanged: callback,
          semanticLabel: 'Reminders',
        ),
      ),
    );
    useKeyboardFocusHighlight();
    final focus = _style(tester).focusColor;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      _painted(tester),
      paints..something(_rrectIn(focus, style: PaintingStyle.stroke)),
    );

    onChanged.value = null;
    await tester.pumpAndSettle();

    expect(
      _painted(tester),
      isNot(paints..something(_rrectIn(focus, style: PaintingStyle.stroke))),
    );
  });

  testWidgets('disabled: no second dim, the switch dims itself', (
    tester,
  ) async {
    await pumpMx(tester, toggle(enabled: false));
    final style = _style(tester);
    final off = <FVariant>{FFormFieldVariant.disabled};

    expect(
      find.ancestor(of: _switch(), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(tester.widget<FSwitch>(_switch()).enabled, isFalse);
    expect(
      _painted(tester),
      _paintsSwitch(
        track: style.trackColor.resolve(off),
        thumb: style.thumbColor.resolve(off),
      ),
    );
    expect(
      style.trackColor.resolve(off),
      isNot(style.trackColor.resolve(<FVariant>{})),
    );
  });

  testWidgets('a disabled toggle takes no tap', (tester) async {
    await pumpMx(tester, toggle(enabled: false));
    await tester.tap(find.byType(MxToggle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // SW-REV-006: a toggle that cannot change is announced as disabled.
  testWidgets('a toggle that cannot change is disabled to TalkBack', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, toggle(enabled: false));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminders')),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });
}

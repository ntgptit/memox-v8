import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/widget_harness.dart';

const _ringKey = ValueKey('mx-toggle-focus-ring');

// The Material 3 switch: a 52x32 track inside a 60x48 box (4 either side of
// the track, a 48 touch height), a 16 handle off, 24 on, 28 pressed.
const _boxSize = Size(60, 48);
const _trackSize = Size(52, 32);

Finder _switch() => find.byType(Switch);

/// What the Switch paints: its one CustomPaint draws the track, its outline
/// and the handle.
RenderObject _painted(WidgetTester tester) => tester.renderObject(
  find.descendant(of: _switch(), matching: find.byType(CustomPaint)),
);

/// The Switch's three strokes in paint order: the track, its outline edge and
/// the handle in [handle] (a 16 circle off, a 24 one on).
PaintPattern _paintsSwitch({
  required Color track,
  required Color edge,
  required Color handleColor,
  required RRect handle,
}) => paints
  ..rrect(color: track, style: PaintingStyle.fill)
  ..rrect(color: edge, style: PaintingStyle.stroke)
  ..rrect(color: handleColor, rrect: handle);

void main() {
  final scheme = lightColorScheme;
  const dimens = AppDimens();

  testWidgets('is a Material switch at the M3 size, read from the theme', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );

    expect(tester.getSize(_switch()), _boxSize);
    expect(tester.widget<Switch>(_switch()).value, isFalse);
    // No per-widget colours or sizes: the theme's slot is the one source.
    final sw = tester.widget<Switch>(_switch());
    expect(sw.thumbColor, isNull);
    expect(sw.trackColor, isNull);
    expect(sw.trackOutlineColor, isNull);
    expect(sw.materialTapTargetSize, isNull);
  });

  testWidgets('off: highest track, outline edge, outline handle 16', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    expect(
      _painted(tester),
      _paintsSwitch(
        track: scheme.surfaceContainerHighest,
        edge: scheme.outline,
        handleColor: scheme.outline,
        handle: RRect.fromLTRBR(12, 16, 28, 32, const Radius.circular(8)),
      ),
    );
  });

  testWidgets('on: primary track, no edge, onPrimary handle 24', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    expect(
      _painted(tester),
      _paintsSwitch(
        track: scheme.primary,
        edge: Colors.transparent,
        handleColor: scheme.onPrimary,
        handle: RRect.fromLTRBR(28, 12, 52, 36, const Radius.circular(12)),
      ),
    );
  });

  testWidgets('a tap reports the flipped value', (tester) async {
    bool? reported;
    await pumpMx(
      tester,
      MxToggle(
        isOn: false,
        onChanged: (v) => reported = v,
        semanticLabel: 'Reminders',
      ),
    );
    await tester.tap(find.byType(MxToggle));

    expect(reported, isTrue);
  });

  testWidgets('announced as a labelled toggle with a 48 target', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );

    expect(
      tester.getSemantics(find.byType(MxToggle)),
      isSemantics(label: 'Reminders', isToggled: true, hasToggledState: true),
    );
    expect(tester.getSize(find.byType(MxToggle)).height, 48);
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  testWidgets('focus draws the primary ring round the track, offset', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    expect(find.byKey(_ringKey), findsNothing);
    final before = tester.getRect(_switch());
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final ring = tester.widget<DecoratedBox>(find.byKey(_ringKey));
    final shape = (ring.decoration as ShapeDecoration).shape;
    expect(
      shape,
      MxFocusRingBorder(
        base: const StadiumBorder(),
        ring: BorderSide(color: scheme.primary, width: dimens.strokeFocus),
        gap: dimens.strokeFocusGap,
      ),
    );
    expect(tester.getSize(find.byKey(_ringKey)), _trackSize);
    expect(tester.getCenter(find.byKey(_ringKey)), before.center);
    expect(tester.getRect(_switch()), before);
  });

  // M3F-15: the SDK maps an engaged on handle to primaryContainer, which
  // equals the primary track in this palette: the handle vanished.
  testWidgets('M3F-15: a pressed on switch keeps its onPrimary handle', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    final press = await tester.startGesture(tester.getCenter(_switch()));
    await tester.pumpAndSettle();

    expect(
      _painted(tester),
      paints
        ..rrect(color: scheme.primary, style: PaintingStyle.fill)
        ..rrect(color: Colors.transparent, style: PaintingStyle.stroke)
        ..rrect(color: scheme.onPrimary),
    );
    await press.up();
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
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byKey(_ringKey), findsOneWidget);

    onChanged.value = null;
    await tester.pumpAndSettle();

    expect(find.byKey(_ringKey), findsNothing);
  });

  testWidgets('disabled: no second dim, the switch dims itself', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxToggle(isOn: false, onChanged: null, semanticLabel: 'Reminders'),
    );

    expect(
      find.ancestor(of: _switch(), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(tester.widget<Switch>(_switch()).onChanged, isNull);
    expect(
      _painted(tester),
      _paintsSwitch(
        track: scheme.surfaceContainerHighest.withValues(
          alpha: dimens.opacityDisabledContainer,
        ),
        edge: scheme.onSurface.withValues(
          alpha: dimens.opacityDisabledContainer,
        ),
        // Material lays the translucent handle over the surface, so the
        // track does not show through it.
        handleColor: Color.alphaBlend(
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContent),
          scheme.surface,
        ),
        handle: RRect.fromLTRBR(12, 16, 28, 32, const Radius.circular(8)),
      ),
    );
  });

  // SW-REV-006: a toggle that cannot change is announced as disabled.
  testWidgets('a toggle that cannot change is disabled to TalkBack', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxToggle(isOn: false, onChanged: null, semanticLabel: 'Reminders'),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminders')),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });
}

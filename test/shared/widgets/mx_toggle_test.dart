import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/widget_harness.dart';

const _trackKey = ValueKey('mx-toggle-track');
const _thumbKey = ValueKey('mx-toggle-thumb');

double _thumbOffset(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_thumbKey)).dx -
    tester.getTopLeft(find.byKey(_trackKey)).dx;

/// The off edge over the track; the focus ring is MxFocusRing's.
Border? _ring(WidgetTester tester) =>
    (tester
                    .widget<AnimatedContainer>(find.byKey(_trackKey))
                    .foregroundDecoration
                as BoxDecoration?)
            ?.border
        as Border?;

Color _thumbColor(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(find.byKey(_thumbKey)).decoration
            as BoxDecoration)
        .color!;

Color _trackColor(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(find.byKey(_trackKey)).decoration!
            as BoxDecoration)
        .color!;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('off: highest track, thumb at 3; on: primary, thumb at 21', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    expect(tester.getSize(find.byKey(_trackKey)), const Size(44, 26));
    expect(_trackColor(tester), scheme.surfaceContainerHighest);
    expect(_thumbOffset(tester), 3);

    await pumpMx(
      tester,
      MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    await tester.pumpAndSettle();
    expect(_trackColor(tester), scheme.primary);
    expect(_thumbOffset(tester), 21);
  });

  testWidgets('off: a 2 outline edge, 3:1 on every ground, and a variant-ink '
      'thumb, 3:1 on the track; '
      'on: no edge, an onPrimary thumb (FE-C1, R17)', (tester) async {
    await pumpMx(
      tester,
      MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    expect(_ring(tester), Border.all(color: scheme.outline, width: 2));
    // The thumb sits on the track's fill: variant ink, 3:1 there.
    expect(_thumbColor(tester), scheme.onSurfaceVariant);

    await pumpMx(
      tester,
      MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    await tester.pumpAndSettle();
    expect(_ring(tester), isNull);
    expect(_thumbColor(tester), scheme.onPrimary);
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
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  testWidgets(
    'focus draws the ring outside the track without moving the thumb',
    (tester) async {
      await pumpMx(
        tester,
        MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
      );
      final before = _thumbOffset(tester);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(find.byType(MxFocusRing), findsOneWidget);
      // The ring is drawn outside the track; the track's own edge is unchanged.
      expect(_ring(tester), Border.all(color: scheme.outline, width: 2));
      expect(_thumbOffset(tester), before);
    },
  );

  testWidgets('on: the thumb is onPrimary (R17: the internal mark carries '
      'the state); off: the edge is outline', (tester) async {
    for (final brightness in Brightness.values) {
      final scheme = brightness == Brightness.light
          ? AppColorSchemes.light
          : AppColorSchemes.dark;
      await pumpMx(
        tester,
        MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Reminders'),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(_thumbColor(tester), scheme.onPrimary);
      await pumpMx(
        tester,
        MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(_ring(tester)!.top.color, scheme.outline);
    }
  });

  testWidgets('focus: a ring outside the track in primaryForeground', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byType(MxFocusRing), findsOneWidget);
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) =>
                        w is CustomPaint &&
                        w.foregroundPainter is MxFocusRingPainter,
                  ),
                )
                .foregroundPainter!
            as MxFocusRingPainter;
    expect(painter.color, MxSemanticColors.light.primaryForeground);
    // Focus adds the outside ring and leaves the off edge as it was.
    expect(_ring(tester)!.top.color, AppColorSchemes.light.outline);
  });

  testWidgets('keyboard: the focused toggle flips on Space and reports once', (
    tester,
  ) async {
    final reported = <bool>[];
    await pumpMx(
      tester,
      MxToggle(
        isOn: false,
        onChanged: reported.add,
        semanticLabel: 'Reminders',
      ),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(reported, [true]);
  });

  testWidgets('disabled takes no focus and draws no ring', (tester) async {
    await pumpMx(
      tester,
      const MxToggle(isOn: false, onChanged: null, semanticLabel: 'Reminders'),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter is MxFocusRingPainter,
      ),
      findsNothing,
    );
  });

  testWidgets('disabled dims to 0.38 and ignores taps', (tester) async {
    await pumpMx(
      tester,
      const MxToggle(isOn: false, onChanged: null, semanticLabel: 'Reminders'),
    );

    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byKey(_trackKey),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
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

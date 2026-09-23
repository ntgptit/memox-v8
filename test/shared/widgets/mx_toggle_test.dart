import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/widget_harness.dart';

const _trackKey = ValueKey('mx-toggle-track');
const _thumbKey = ValueKey('mx-toggle-thumb');

double _thumbOffset(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_thumbKey)).dx -
    tester.getTopLeft(find.byKey(_trackKey)).dx;

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

  testWidgets('focus draws the ring without moving the thumb', (tester) async {
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

    expect(
      tester
          .widget<AnimatedContainer>(find.byKey(_trackKey))
          .foregroundDecoration,
      isNotNull,
    );
    expect(_thumbOffset(tester), before);
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
}

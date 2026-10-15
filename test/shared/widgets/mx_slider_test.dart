import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

import '../../support/widget_harness.dart';

// Spec §13.8, DSD-23: Material 3's Slider under the theme's sliderTheme,
// inactive track surfaceContainerHighest (owner 2026-10-15).
void main() {
  final scheme = lightColorScheme;
  const dimens = AppDimens();
  Finder slider() => find.byType(Slider);

  testWidgets('is a Material slider read from the theme', (tester) async {
    await pumpMx(
      tester,
      MxSlider(
        value: 3000,
        max: 10000,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
      ),
    );
    final widget = tester.widget<Slider>(slider());
    expect(widget.value, 3000);
    expect(widget.max, 10000);
    expect(widget.activeColor, isNull);
    expect(widget.inactiveColor, isNull);
    expect(widget.thumbColor, isNull);
    final theme = SliderTheme.of(tester.element(slider()));
    expect(theme.activeTrackColor, scheme.primary);
    expect(theme.inactiveTrackColor, scheme.surfaceContainerHighest);
    expect(theme.thumbColor, scheme.primary);
  });

  testWidgets('drags report the new value and its end', (tester) async {
    double? changed;
    double? ended;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxSlider(
          value: 0,
          max: 10000,
          onChanged: (value) => changed = value,
          onChangeEnd: (value) => ended = value,
          semanticLabel: 'Audio position',
        ),
      ),
    );
    await tester.drag(slider(), const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(changed, greaterThan(0));
    expect(ended, changed);
  });

  testWidgets('a value past max is drawn at max', (tester) async {
    await pumpMx(
      tester,
      MxSlider(
        value: 12000,
        max: 10000,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
      ),
    );
    expect(tester.widget<Slider>(slider()).value, 10000);
  });

  testWidgets('max 0 is a disabled slider, never an assertion', (tester) async {
    await pumpMx(
      tester,
      MxSlider(
        value: 0,
        max: 0,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
      ),
    );
    final widget = tester.widget<Slider>(slider());
    expect(widget.onChanged, isNull);
    final theme = SliderTheme.of(tester.element(slider()));
    expect(
      theme.disabledActiveTrackColor,
      scheme.onSurface.withValues(alpha: dimens.opacityDisabledContent),
    );
  });

  testWidgets('keyboard focus draws the primary overlay round the handle', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxSlider(
        value: 5000,
        max: 10000,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
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

    expect(
      tester.renderObject(slider()),
      paints
        ..circle(color: scheme.primary.withValues(alpha: dimens.opacityFocus)),
    );
  });

  testWidgets('announced with its label and value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxSlider(
        value: 5000,
        max: 10000,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
        semanticFormatter: (value) => '${(value / 1000).round()}s',
      ),
    );
    expect(find.bySemanticsLabel('Audio position'), findsOneWidget);
    final data = tester.getSemantics(find.byType(MxSlider)).getSemanticsData();
    expect(data.label, 'Audio position');
    expect(data.value, '5s');
    expect(data.flagsCollection.isSlider, isTrue);
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    expect(data.hasAction(SemanticsAction.decrease), isTrue);
    handle.dispose();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  testWidgets('ghost: no fill, onSurfaceVariant label, a trailing chevron', (
    tester,
  ) async {
    await pumpMx(tester, MxChipTrigger(label: 'Sort: Due', onPressed: () {}));
    final material = tester.widget<Material>(_painted.first);

    expect(tester.getSize(_painted.first).height, 28);
    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, AppColorSchemes.light.onSurfaceVariant);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
    expect(tester.getSize(find.byIcon(AppIcons.chevronDown)).width, 16);
  });

  testWidgets('opens its menu on tap and meets the 48 target', (tester) async {
    var taps = 0;
    await pumpMx(tester, MxChipTrigger(label: 'Sort', onPressed: () => taps++));
    await tester.tap(find.byType(MxChipTrigger));

    expect(taps, 1);
    await expectAccessibleTargets(tester);
  });

  ButtonStyle style(WidgetTester tester) =>
      tester.widget<TextButton>(find.byType(TextButton)).style!;

  testWidgets('a hairline ghost edge at rest (critique 28)', (tester) async {
    await pumpMx(tester, MxChipTrigger(label: 'Level', onPressed: () {}));
    final side = style(tester).side!.resolve(const {})!;
    expect(side.width, AppStroke.hairline);
    expect(
      side.color,
      MxDerivedColors.resolve(
        AppColorSchemes.light,
        MxSemanticColors.light,
      ).ghostBorder,
    );
  });

  testWidgets('active: primaryContainer ground, onPrimaryContainer ink, '
      'a primaryInk edge', (tester) async {
    await pumpMx(
      tester,
      MxChipTrigger(label: 'Level · Error', isActive: true, onPressed: () {}),
    );
    final scheme = AppColorSchemes.light;
    expect(
      style(tester).backgroundColor!.resolve(const {}),
      scheme.primaryContainer,
    );
    expect(
      style(tester).foregroundColor!.resolve(const {}),
      scheme.onPrimaryContainer,
    );
    final side = style(tester).side!.resolve(const {})!;
    expect(side.width, AppStroke.hairline);
    expect(
      side.color,
      MxDerivedColors.resolve(scheme, MxSemanticColors.light).primaryInk,
    );
  });
}

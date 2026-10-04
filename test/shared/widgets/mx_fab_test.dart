import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('a square 52 primary box, radius 16, 20 onPrimary glyph', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () {}),
    );
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(MxFab), matching: find.byType(Material)),
    );

    expect(tester.getSize(find.byType(MxFab)), const Size.square(52));
    expect(material.color, scheme.primary);
    expect(
      (material.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(16),
    );
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.add)).color,
      scheme.onPrimary,
    );
    expect(tester.getSize(find.byIcon(AppIcons.add)).width, 20);
  });

  testWidgets('lifted by the fab shadow', (tester) async {
    await pumpMx(
      tester,
      MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () {}),
    );
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxFab),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    expect((box.decoration as BoxDecoration).boxShadow, AppShadows.fab(scheme));
  });

  testWidgets('the label is its accessible name, never painted', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxFab(
        icon: AppIcons.add,
        semanticLabel: 'New deck',
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.bySemanticsLabel('New deck'));

    expect(find.text('New deck'), findsNothing);
    expect(taps, 1);
    handle.dispose();
    await expectAccessibleTargets(tester);
  });
}

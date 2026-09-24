import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_outcome_tile.dart';

import '../../support/widget_harness.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final tone in MxOutcomeTone.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${tone.name}, ${brightness.name}: the label reads 4.5:1 on its '
        'ground in a dialog',
        (tester) async {
          await pumpMx(
            tester,
            SizedBox(
              width: 160,
              child: MxOutcomeTile(label: 'Label', body: 'Body', tone: tone),
            ),
            brightness: brightness,
          );
          final scheme = brightness == Brightness.light
              ? AppColorSchemes.light
              : AppColorSchemes.dark;
          final label = tester.widget<Text>(find.text('Label'));
          final box = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(MxOutcomeTile),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          final ground = Color.alphaBlend(
            (box.decoration as BoxDecoration).color!,
            scheme.surfaceContainerHigh,
          );

          expect(
            _ratio(label.style!.color!, ground),
            greaterThanOrEqualTo(4.5),
          );
          expect(find.text('Body'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('kept reads in the mastered ink, lost in the warning ink', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const Column(
        children: [
          MxOutcomeTile(label: 'Kept', body: 'a', tone: MxOutcomeTone.kept),
          MxOutcomeTile(label: 'Lost', body: 'b', tone: MxOutcomeTone.lost),
        ],
      ),
    );
    final context = tester.element(find.text('Kept'));

    expect(
      tester.widget<Text>(find.text('Kept')).style!.color,
      context.derivedColors.statusMasteredInk,
    );
    expect(
      tester.widget<Text>(find.text('Lost')).style!.color,
      context.derivedColors.warningInk,
    );
  });
}

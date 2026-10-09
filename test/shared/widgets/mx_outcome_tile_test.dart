import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
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

  testWidgets('kept is the success container, lost the warning container: '
      'the label and the body read in the on-colour, with no edge', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final semantic = brightness == Brightness.light
          ? MxSemanticColors.light
          : MxSemanticColors.dark;
      await pumpMx(
        tester,
        const Column(
          children: [
            MxOutcomeTile(label: 'Kept', body: 'a', tone: MxOutcomeTone.kept),
            MxOutcomeTile(label: 'Lost', body: 'b', tone: MxOutcomeTone.lost),
          ],
        ),
        brightness: brightness,
      );
      // The theme animates from the previous brightness.
      await tester.pumpAndSettle();
      BoxDecoration ground(String label) =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text(label),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;

      expect(ground('Kept').color, semantic.successContainer);
      expect(ground('Lost').color, semantic.warningContainer);
      expect(ground('Kept').border, isNull);
      expect(ground('Lost').border, isNull);
      expect(
        tester.widget<Text>(find.text('Kept')).style!.color,
        semantic.onSuccessContainer,
      );
      expect(
        tester.widget<Text>(find.text('Lost')).style!.color,
        semantic.onWarningContainer,
      );
      // The body reads in the on-colour too: onSurfaceVariant is 4.19 / 4.17
      // on the dark warning / success container (spec 2026-10-08 §4.5).
      expect(
        tester.widget<Text>(find.text('a')).style!.color,
        semantic.onSuccessContainer,
      );
      expect(
        tester.widget<Text>(find.text('b')).style!.color,
        semantic.onWarningContainer,
      );
    }
  });
}

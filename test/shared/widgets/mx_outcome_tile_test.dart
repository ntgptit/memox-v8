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
        '${tone.name}, ${brightness.name}: the label reads on its light soft '
        'ground, at AA or at its recorded floor (owner 2026-10-10)',
        (tester) async {
          await pumpMx(
            tester,
            SizedBox(
              width: 160,
              child: MxOutcomeTile(label: 'Label', body: 'Body', tone: tone),
            ),
            brightness: brightness,
          );
          final label = tester.widget<Text>(find.text('Label'));
          final box = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(MxOutcomeTile),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          final ground = (box.decoration as BoxDecoration).color!;
          // Lost reads #997700 on #FFEDAB: the 3.59 floor that
          // token_contrast_test records (spec 2026-10-10 D3).
          final floor = tone == MxOutcomeTone.kept ? 4.5 : 3.59;

          expect(
            _ratio(label.style!.color!, ground),
            greaterThanOrEqualTo(floor),
          );
          expect(find.text('Body'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('kept reads onSuccessSoft, lost onWarningSoft, the body Day\'s '
      'description; the same in Night (spec 2026-10-10 D4)', (tester) async {
    await pumpMx(
      tester,
      const Column(
        children: [
          MxOutcomeTile(label: 'Kept', body: 'a', tone: MxOutcomeTone.kept),
          MxOutcomeTile(label: 'Lost', body: 'b', tone: MxOutcomeTone.lost),
        ],
      ),
    );
    const semantic = MxSemanticColors.dark;
    await pumpMx(
      tester,
      const Column(
        children: [
          MxOutcomeTile(label: 'Kept', body: 'a', tone: MxOutcomeTone.kept),
          MxOutcomeTile(label: 'Lost', body: 'b', tone: MxOutcomeTone.lost),
        ],
      ),
      brightness: Brightness.dark,
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('Kept')).style!.color,
      semantic.onSuccessSoft,
    );
    expect(
      tester.widget<Text>(find.text('Lost')).style!.color,
      semantic.onWarningSoft,
    );
    expect(
      tester.widget<Text>(find.text('a')).style!.color,
      AppColorSchemes.light.onSurfaceVariant,
    );
  });
}

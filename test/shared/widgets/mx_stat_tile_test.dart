import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

import '../../support/widget_harness.dart';

// FE-A6 D17: a figure over its label, screens 14 and 21.
void main() {
  testWidgets('one node reads the label, then the value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxStatTile(value: '12', label: 'Due'));

    expect(
      tester.getSemantics(find.byType(MxStatTile)),
      matchesSemantics(label: 'Due', value: '12'),
    );
    handle.dispose();
  });

  testWidgets('primary takes the primary text, muted the variant text, plain '
      'the surface text', (tester) async {
    await pumpMx(
      tester,
      const Column(
        children: [
          MxStatTile(
            value: '1',
            label: 'a',
            emphasis: MxStatTileEmphasis.primary,
          ),
          MxStatTile(value: '2', label: 'b'),
          MxStatTile(
            value: '3',
            label: 'c',
            emphasis: MxStatTileEmphasis.muted,
          ),
        ],
      ),
    );
    Color? foreground(String value) =>
        tester.widget<Text>(find.text(value)).style?.color;
    final scheme = AppColorSchemes.light;

    expect(foreground('1'), MxSemanticColors.light.primaryText);
    expect(foreground('2'), scheme.onSurface);
    expect(foreground('3'), scheme.onSurfaceVariant);
  });

  testWidgets('the label is upper-cased and a boxed tile does not clip', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 120,
        child: MxStatTile(
          value: '3 / 23',
          label: 'Wrong',
          layout: MxStatTileLayout.boxed,
        ),
      ),
    );

    expect(find.text('WRONG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long value keeps one line in a narrow column (critique '
      '2026-09-30 part 3c-1)', (tester) async {
    await pumpMx(
      tester,
      const Center(
        child: SizedBox(
          width: 96,
          child: MxStatTile(value: '241 of 241', label: 'Wrong turns'),
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('241 of 241')).maxLines, 1);
    expect(
      find.ancestor(
        of: find.text('241 of 241'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  // DEV-231 (UI-REV-002): a boxed tile sits on the Muted Fill, not the
  // card's own surface, so it stays a visible box on the plain study-entry
  // card (ruling E5 made the hero a plain card on surfaceContainerLowest).
  testWidgets('a boxed tile fills with the Muted Fill', (tester) async {
    await pumpMx(
      tester,
      const MxStatTile(
        value: '4',
        label: 'Due',
        layout: MxStatTileLayout.boxed,
      ),
    );
    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text('4'), matching: find.byType(DecoratedBox)),
    );
    expect(
      (box.decoration as BoxDecoration).color,
      AppColorSchemes.light.surfaceContainerLow,
    );
  });

  testWidgets('the label is an eyebrow (critique 2026-09-30 part 2, P1)', (
    tester,
  ) async {
    await pumpMx(tester, const MxStatTile(value: '3', label: 'Wrong turns'));
    final label = find.text('WRONG TURNS');
    expect(
      tester.widget<Text>(label).style,
      tester.element(label).textStyles.eyebrow,
    );
  });
}

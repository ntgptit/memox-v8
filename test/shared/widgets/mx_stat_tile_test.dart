import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_palette.dart';

import '../../support/theme_expect.dart';

import 'package:memox/shared/widgets/mx_stat_tile.dart';

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

  // Q-P6-5 (owner, 2026-10-16): a figure with no value shows a dash, which
  // TalkBack reads as "en dash"; the caller says what it means instead.
  testWidgets('a spoken value replaces the shown one for a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxStatTile(value: '–', semanticValue: 'None yet', label: 'Best'),
    );

    expect(find.text('–'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(MxStatTile)),
      matchesSemantics(label: 'Best', value: 'None yet'),
    );
    handle.dispose();
  });

  testWidgets('primary takes the primary text, muted the variant text, plain '
      'the surface ink', (tester) async {
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
    Color? ink(String value) =>
        tester.widget<Text>(find.text(value)).style?.color;
    final scheme = lightColorScheme;

    expect(ink('1'), accentOf(scheme));
    expect(ink('2'), scheme.onSurface);
    expect(ink('3'), scheme.onSurfaceVariant);
  });

  // DEV-231 (UI-REV-002): a boxed tile sits on the muted fill, not the
  // card's own ground, so it stays a visible box on the study-entry card.
  testWidgets('a boxed tile fills with surfaceContainerLow', (tester) async {
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
      appLightColors.muted,
    );
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

  testWidgets('the label is an eyebrow (critique 2026-09-30 part 2, P1)', (
    tester,
  ) async {
    await pumpMx(tester, const MxStatTile(value: '3', label: 'Wrong turns'));
    final label = find.text('WRONG TURNS');
    expect(
      tester.widget<Text>(label).style,
      tester
          .element(label)
          .texts
          .labelSmall
          ?.copyWith(color: tester.element(label).colors.mutedForeground),
    );
  });
}

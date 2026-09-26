import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
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

  testWidgets('primary takes the primary ink, muted the variant ink, plain '
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
    final scheme = AppColorSchemes.light;

    expect(ink('1'), scheme.primary);
    expect(ink('2'), scheme.onSurface);
    expect(ink('3'), scheme.onSurfaceVariant);
  });

  testWidgets('the label is upper-cased and a boxed tile does not clip at '
      'text scale 2', (tester) async {
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
      textScale: 2,
    );

    expect(find.text('WRONG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

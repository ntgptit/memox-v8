import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';

import '../../support/widget_harness.dart';

Finder _hairlines() => find.byType(Divider);

void main() {
  testWidgets('n children get n - 1 hairlines, 1 tall, between them', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxDividedColumn(
        children: [
          SizedBox(key: ValueKey('a'), height: 48),
          SizedBox(key: ValueKey('b'), height: 48),
          SizedBox(key: ValueKey('c'), height: 48),
        ],
      ),
    );

    expect(_hairlines(), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('b'))).dy -
          tester.getBottomLeft(find.byKey(const ValueKey('a'))).dy,
      1,
    );
  });

  testWidgets('the hairline is the divider role, inset 16 on each side (M3 '
      'inset divider)', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 328,
        child: MxDividedColumn(
          children: [
            SizedBox(key: ValueKey('a'), height: 48),
            SizedBox(key: ValueKey('b'), height: 48),
          ],
        ),
      ),
    );
    final column = tester.getRect(find.byType(MxDividedColumn));
    final line = find.descendant(
      of: find.byType(Divider),
      matching: find.byType(DecoratedBox),
    );
    final edge =
        ((tester.widget<DecoratedBox>(line).decoration as BoxDecoration).border!
                as Border)
            .bottom;

    expect(edge.color, MxColorsExtension.light.divider);
    expect(edge.color, isNot(lightColorScheme.outlineVariant));
    expect(tester.getRect(line).left - column.left, 16);
    expect(column.right - tester.getRect(line).right, 16);
  });

  testWidgets('one child draws no hairline', (tester) async {
    await pumpMx(
      tester,
      const MxDividedColumn(children: [SizedBox(height: 48)]),
    );

    expect(_hairlines(), findsNothing);
  });

  testWidgets('divided rows inside a lazy list keep n - 1 hairlines and stay '
      'lazy (final review)', (tester) async {
    await pumpMx(
      tester,
      ListView(
        children: MxDividedColumn.divided([
          for (var i = 0; i < 200; i++)
            SizedBox(key: ValueKey('row-$i'), height: 48),
        ]),
      ),
    );

    // Only the rows in view and the cache extent are built.
    expect(find.byKey(const ValueKey('row-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('row-199')), findsNothing);
    final rows = tester
        .widgetList(
          find.byWidgetPredicate(
            (widget) => switch (widget.key) {
              ValueKey<String>(:final value) => value.startsWith('row-'),
              _ => false,
            },
          ),
        )
        .length;
    expect(rows, lessThan(100));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row-1'))).dy -
          tester.getBottomLeft(find.byKey(const ValueKey('row-0'))).dy,
      1,
    );
    expect(_hairlines(), findsNWidgets(rows - 1));
  });
}

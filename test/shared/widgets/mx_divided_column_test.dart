import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';

import '../../support/widget_harness.dart';

Iterable<ColoredBox> _hairlines(WidgetTester tester) {
  final ghost = MxDerivedColors.resolve(
    AppColorSchemes.light,
    MxSemanticColors.light,
  ).ghostBorder;
  return tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .where((box) => box.color == ghost);
}

void main() {
  testWidgets('n children get n - 1 ghost hairlines, 1 tall, between them', (
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

    expect(_hairlines(tester), hasLength(2));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('b'))).dy -
          tester.getBottomLeft(find.byKey(const ValueKey('a'))).dy,
      1,
    );
  });

  testWidgets('one child draws no hairline', (tester) async {
    await pumpMx(
      tester,
      const MxDividedColumn(children: [SizedBox(height: 48)]),
    );

    expect(_hairlines(tester), isEmpty);
  });
}

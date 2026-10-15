import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_two_columns.dart';

import '../../support/widget_harness.dart';

const _a = Key('a');
const _b = Key('b');

Widget _at(
  double width, {
  List<Widget> end = const [SizedBox(key: _b, height: 40)],
}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: width,
    child: MxTwoColumns(
      start: const [SizedBox(key: _a, height: 40)],
      end: end,
    ),
  ),
);

void main() {
  testWidgets('below minWidth the end blocks follow the start in one column', (
    tester,
  ) async {
    await pumpMx(tester, _at(MxTwoColumns.minWidth - 1));

    expect(
      tester.getTopLeft(find.byKey(_b)).dy,
      greaterThan(tester.getBottomLeft(find.byKey(_a)).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(_b)).dx,
      tester.getTopLeft(find.byKey(_a)).dx,
    );
  });

  testWidgets('from minWidth the end blocks sit beside the start', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpMxAt(tester, _at(MxTwoColumns.minWidth));

    expect(
      tester.getTopLeft(find.byKey(_b)).dy,
      tester.getTopLeft(find.byKey(_a)).dy,
    );
    expect(
      tester.getTopLeft(find.byKey(_b)).dx,
      greaterThan(tester.getTopRight(find.byKey(_a)).dx),
    );
  });

  // Progress never studied has no end blocks: the start takes the full width
  // instead of half of it beside a blank half.
  testWidgets('with no end blocks the start keeps the full width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpMxAt(tester, _at(MxTwoColumns.minWidth + 100, end: const []));

    expect(tester.getSize(find.byKey(_a)).width, MxTwoColumns.minWidth + 100);
  });
}

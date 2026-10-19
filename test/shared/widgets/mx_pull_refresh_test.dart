import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_pull_refresh.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('a pull down refreshes a list shorter than the screen', (
    tester,
  ) async {
    var refreshes = 0;
    await pumpMx(
      tester,
      MxPullRefresh(
        onRefresh: () async => refreshes++,
        child: ListView(children: const [Text('one row')]),
      ),
    );

    await tester.fling(find.text('one row'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refreshes, 1);
  });

  testWidgets('a long list still scrolls and refreshes from its top', (
    tester,
  ) async {
    var refreshes = 0;
    await pumpMx(
      tester,
      MxPullRefresh(
        onRefresh: () async => refreshes++,
        child: ListView(
          children: [for (var i = 0; i < 60; i++) Text('row $i')],
        ),
      ),
    );

    await tester.drag(find.text('row 3'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('row 0'), findsNothing);
    expect(refreshes, 0);
  });
}

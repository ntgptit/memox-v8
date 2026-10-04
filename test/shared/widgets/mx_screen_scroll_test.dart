import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

import 'support/mx_harness.dart';

const Key _last = ValueKey<String>('last');

Widget _rows() => MxScreenScroll(
  children: [
    for (var i = 0; i < 30; i++) const SizedBox(height: 56, child: Text('Row')),
    const SizedBox(key: _last, height: 56),
  ],
);

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: mxThemes['light'], home: screen));
}

Future<void> _toEnd(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable), const Offset(0, -5000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a 16 gutter on both sides', (tester) async {
    await _pump(tester, MxScreenScaffold(body: _rows()));
    final Rect row = tester.getRect(find.text('Row').first);
    expect(row.left, AppSpacing.gutter);
    expect(
      tester
          .getRect(
            find
                .ancestor(
                  of: find.text('Row').first,
                  matching: find.byType(SizedBox),
                )
                .first,
          )
          .right,
      400 - AppSpacing.gutter,
    );
  });

  testWidgets('a 48 tail under pinned chrome', (tester) async {
    await _pump(tester, MxScreenScaffold(body: _rows()));
    await _toEnd(tester);
    expect(tester.getRect(find.byKey(_last)).bottom, 800 - AppSpacing.pageEnd);
  });

  testWidgets('the last item ends clear of a FAB', (tester) async {
    await _pump(
      tester,
      MxScreenScaffold(
        body: _rows(),
        fab: MxFab(icon: Icons.add, semanticLabel: 'New', onPressed: () {}),
      ),
    );
    await _toEnd(tester);
    expect(
      tester.getRect(find.byKey(_last)).bottom,
      tester.getRect(find.byType(MxFab)).top - AppSpacing.gutter,
    );
  });

  testWidgets('a long list builds as it scrolls in', (tester) async {
    await _pump(
      tester,
      MxScreenScaffold(
        body: MxScreenScroll.builder(
          itemCount: 1000,
          itemBuilder: (_, index) =>
              SizedBox(height: 56, child: Text('$index')),
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.text('999'), findsNothing);
  });
}

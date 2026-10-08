import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

import '../../support/widget_harness.dart';

Widget _horizontal({double content = 600, bool reverse = false}) => SizedBox(
  width: 200,
  height: 48,
  child: MxScrollFade(
    axis: Axis.horizontal,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: reverse,
      child: SizedBox(width: content, height: 48),
    ),
  ),
);

Widget _vertical({
  double content = 600,
  MxScrollFadeGround ground = MxScrollFadeGround.page,
}) => SizedBox(
  width: 200,
  height: 200,
  child: MxScrollFade(
    ground: ground,
    child: SingleChildScrollView(child: SizedBox(width: 200, height: content)),
  ),
);

Color _lastStop(WidgetTester tester, Key key) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byKey(key), matching: find.byType(DecoratedBox)),
  );
  return ((box.decoration as BoxDecoration).gradient! as LinearGradient)
      .colors
      .last;
}

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('content that fits shows no fade', (tester) async {
    await pumpMx(tester, _horizontal(content: 100));
    await tester.pump();

    expect(find.byKey(MxScrollFade.leadingKey), findsNothing);
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('horizontal: the edge with more content fades, and follows the '
      'scroll', (tester) async {
    await pumpMx(tester, _horizontal());
    await tester.pump();
    expect(find.byKey(MxScrollFade.leadingKey), findsNothing);
    expect(find.byKey(MxScrollFade.trailingKey), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-1000, 0),
    );
    await tester.pump();
    expect(find.byKey(MxScrollFade.leadingKey), findsOneWidget);
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('a reversed horizontal scroll opens at its end: the start edge '
      'fades (MxBreadcrumb)', (tester) async {
    await pumpMx(tester, _horizontal(reverse: true));
    await tester.pump();

    expect(find.byKey(MxScrollFade.leadingKey), findsOneWidget);
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('vertical: only the bottom edge fades while more lies below', (
    tester,
  ) async {
    await pumpMx(tester, _vertical());
    await tester.pump();
    expect(find.byKey(MxScrollFade.leadingKey), findsNothing);
    expect(find.byKey(MxScrollFade.trailingKey), findsOneWidget);
    expect(tester.getSize(find.byKey(MxScrollFade.trailingKey)).height, 24);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1000),
    );
    await tester.pump();
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('the fade dissolves into its ground and takes no taps', (
    tester,
  ) async {
    await pumpMx(tester, _vertical(ground: MxScrollFadeGround.recessed));
    await tester.pump();

    expect(
      _lastStop(tester, MxScrollFade.trailingKey),
      scheme.surfaceContainerLow,
    );
    expect(
      find.descendant(
        of: find.byKey(MxScrollFade.trailingKey),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });
}

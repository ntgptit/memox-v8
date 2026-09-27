import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

/// The phone frame every shared-widget test runs in (spec §8.2).
const Size phoneSize = Size(360, 800);

void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = phoneSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

MediaQueryData _media(
  BuildContext context, {
  double textScale = 1,
  EdgeInsets padding = EdgeInsets.zero,
}) => MediaQuery.of(context).copyWith(
  textScaler: TextScaler.linear(textScale),
  padding: padding,
  viewPadding: padding,
);

/// Pumps [child] centred in a Scaffold under the MemoX theme.
Future<void> pumpMx(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  _usePhone(tester);
  return tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light
          ? buildLightTheme()
          : buildDarkTheme(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: _media(context, textScale: textScale, padding: padding),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}

/// [pumpMx] at the view size the test already set.
Future<void> pumpMxAt(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: Center(child: child)),
  ),
);

/// Pumps [page] as the whole route, for widgets that own their Scaffold.
Future<void> pumpMxPage(
  WidgetTester tester,
  Widget page, {
  EdgeInsets padding = EdgeInsets.zero,
}) {
  _usePhone(tester);
  return tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: _media(context, padding: padding),
          child: page,
        ),
      ),
    ),
  );
}

/// Every tappable node is at least 48×48 and has a label.
Future<void> expectAccessibleTargets(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

/// Every [parts] widget sits on the vertical centre of [whole]: a row's
/// leading and trailing marks centre on the row, whatever its text height
/// (owner 2026-09-26).
void expectCentredOn(WidgetTester tester, Finder whole, List<Finder> parts) {
  final centre = tester.getRect(whole).center.dy;
  for (final part in parts) {
    expect(part, findsOneWidget);
    expect(
      tester.getRect(part).center.dy,
      closeTo(centre, 0.5),
      reason: '$part is off the centre of $whole',
    );
  }
}

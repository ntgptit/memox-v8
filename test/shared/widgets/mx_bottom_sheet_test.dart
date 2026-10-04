import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

Widget _opener(Widget Function(BuildContext) sheet) => Builder(
  builder: (context) => TextButton(
    onPressed: () => showMxBottomSheet<void>(context, builder: sheet),
    child: const Text('Open'),
  ),
);

void main() {
  testWidgets('it opens with a grabber, a header title and its footer', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _opener(
        (_) => MxBottomSheet(
          title: 'Sort & filter',
          actions: MxSheetActions(
            confirmLabel: 'Apply',
            onConfirm: () {},
            isInSheet: true,
          ),
          child: const SizedBox(height: 80, child: Text('Options')),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Sort & filter')),
      isSemantics(isHeader: true, label: 'Sort & filter'),
    );
    final Finder grabber = find.byWidgetPredicate(
      (w) =>
          w is SizedBox &&
          w.width == AppSize.grabberWidth &&
          w.height == AppSize.grabberHeight,
    );
    expect(grabber, findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a long body stops 72 below the top and scrolls', (tester) async {
    await pumpMx(
      tester,
      _opener(
        (_) => MxBottomSheet(
          child: Column(children: List<Widget>.filled(60, const Text('Row'))),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(MxBottomSheet)).dy,
      greaterThanOrEqualTo(AppSize.sheetTopClearance),
    );
    expect(find.byType(Scrollable), findsOneWidget);
  });

  testWidgets('it rides above the keyboard', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await pumpMx(
      tester,
      _opener((_) => const MxBottomSheet(child: SizedBox(height: 80))),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final double window =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final double keyboard = 300 / tester.view.devicePixelRatio;
    expect(
      tester.getBottomLeft(find.byType(SizedBox).last).dy,
      lessThanOrEqualTo(window - keyboard),
    );
  });

  testWidgets('under reduced motion it opens at once', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: _opener((_) => const MxBottomSheet(child: Text('Body'))),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    // The ink ripple of the tap may still run; the sheet itself is placed.
    final Offset opened = tester.getTopLeft(find.byType(MxBottomSheet));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MxBottomSheet)), opened);
  });

  testWidgets('the title starts on the gutter, in line with the rows', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _opener((_) => const MxBottomSheet(title: 'Sort', child: Text('Row'))),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Sort')).dx -
          tester.getTopLeft(find.byType(MxBottomSheet)).dx,
      AppSpacing.gutter,
    );
  });

  testWidgets('under a status bar it still stops 72 below the safe area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47);
    addTearDown(tester.view.reset);
    await pumpMx(
      tester,
      _opener(
        (_) => MxBottomSheet(
          child: Column(children: List<Widget>.filled(60, const Text('Row'))),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(MxBottomSheet)).dy,
      greaterThanOrEqualTo(47 + AppSize.sheetTopClearance),
    );
  });

  testWidgets('its last row clears the navigation bar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    const Key last = ValueKey<String>('last');
    await pumpMx(
      tester,
      _opener(
        (_) => const MxBottomSheet(child: SizedBox(key: last, height: 80)),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byKey(last)).dy,
      lessThanOrEqualTo(800 - 48),
    );
    expect(tester.getBottomLeft(find.byType(MxBottomSheet)).dy, 800);
  });

  testWidgets('its footer is framed for the sheet without being told', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _opener(
        (_) => MxBottomSheet(
          title: 'Sort & filter',
          actions: MxSheetActions(confirmLabel: 'Done', onConfirm: () {}),
          child: const SizedBox(height: 80),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Done')).left -
          tester.getRect(find.byType(MxBottomSheet)).left,
      greaterThan(16),
    );
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).isInSheet,
      isTrue,
    );
  });
}

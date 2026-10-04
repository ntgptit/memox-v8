import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

MxDialog _dialog(VoidCallback onConfirm, {MxDialogWidth? width}) => MxDialog(
  title: 'Move to Trash?',
  message: '"Spanish" and its 120 cards move to Trash for 30 days.',
  width: width ?? MxDialogWidth.medium,
  actions: MxSheetActions(
    cancelLabel: 'Cancel',
    onCancel: () {},
    confirmLabel: 'Move to Trash',
    onConfirm: onConfirm,
    tone: MxSheetActionsTone.destructive,
  ),
);

void main() {
  testWidgets('it opens over the scrim and closes on its action', (
    tester,
  ) async {
    var confirmed = 0;
    await pumpMx(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showMxDialog<void>(
            context,
            builder: (_) => _dialog(() => confirmed++),
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Move to Trash?'), findsOneWidget);
    final ModalBarrier barrier = tester.widget(find.byType(ModalBarrier).last);
    final ColorScheme s = mxThemes['light']!.colorScheme;
    expect(barrier.color, s.scrim.withValues(alpha: 0.45));
    await tester.tap(find.text('Move to Trash'));
    expect(confirmed, 1);
  });

  for (final width in MxDialogWidth.values) {
    testWidgets('${width.name} is ${width.extent} wide on a wide window', (
      tester,
    ) async {
      await pumpMx(tester, _dialog(() {}, width: width));
      expect(
        tester.getSize(find.byType(DecoratedBox).first).width,
        width.extent,
      );
    });
  }

  testWidgets('the sheet ground at r20, named for TalkBack', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(tester, _dialog(() {}));
    final BoxDecoration box =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
            as BoxDecoration;
    expect(box.color, mxThemes['light']!.colorScheme.surfaceContainerHigh);
    expect(box.borderRadius, BorderRadius.circular(AppRadius.xl));
    expect(find.bySemanticsLabel('Move to Trash?'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('never wider than the window less its gutters', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpMx(tester, _dialog(() {}, width: MxDialogWidth.large));
    expect(
      tester.getSize(find.byType(DecoratedBox).first).width,
      lessThan(AppSize.dialogLarge),
    );
  });

  testWidgets('under reduced motion it opens at once', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showMxDialog<void>(context, builder: (_) => _dialog(() {})),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    final ScaleTransition scale = tester.widget(
      find
          .ancestor(
            of: find.byType(MxDialog),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, 1);
  });
}

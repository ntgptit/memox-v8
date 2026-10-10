import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

Material _surface(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(MxDialog), matching: find.byType(Material))
      .first,
);

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('the card ground at radius 20 with the overlay shadow', (
    tester,
  ) async {
    await pumpMx(tester, const MxDialog(title: 'Delete deck?'));
    final shadow =
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(MxDialog),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .boxShadow;

    expect(_surface(tester).color, scheme.surfaceContainerLowest);
    expect(
      (_surface(tester).shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(20),
    );
    expect(shadow, AppShadows.overlay(scheme));
  });

  testWidgets('width: the column 20 in from each edge, capped at 340/320/300', (
    tester,
  ) async {
    await pumpMx(tester, const MxDialog(title: 'Delete deck?'));
    expect(tester.getSize(find.byType(Material).last).width, 320);

    tester.view.physicalSize = const Size(600, 800);
    for (final (width, cap) in [
      (MxDialogWidth.large, 340.0),
      (MxDialogWidth.medium, 320.0),
      (MxDialogWidth.small, 300.0),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await pumpMxAt(tester, MxDialog(title: 'Delete deck?', width: width));

      expect(tester.getSize(find.byType(Material).last).width, cap);
    }
  });

  testWidgets('title 16/700 over a 14 body, 16 in and 20 down, on the action '
      'pair\'s edge (DEV-166); the route is named', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxDialog(title: 'Delete deck?', body: 'Its cards move to Trash.'),
    );
    final surface = tester.getTopLeft(find.byType(Material).last);

    expect(tester.widget<Text>(find.text('Delete deck?')).style!.fontSize, 16);
    expect(
      tester.widget<Text>(find.text('Its cards move to Trash.')).style!.color,
      scheme.onSurface,
    );
    expect(
      tester.getTopLeft(find.text('Delete deck?')) - surface,
      const Offset(16, 20),
    );
    expect(
      tester.getSemantics(find.byType(MxDialog)),
      isSemantics(label: 'Delete deck?', namesRoute: true, scopesRoute: true),
    );
    handle.dispose();
  });

  testWidgets('showMxDialog: a 56% scrim; a scrim tap returns null (RF2)', (
    tester,
  ) async {
    String? result = 'unset';
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () async => result = await showMxDialog<String>(
            context,
            builder: (_) => const MxDialog(title: 'Delete deck?'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
      scheme.scrim.withValues(alpha: 0.56),
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(result, isNull);
  });

  testWidgets('reduced motion opens with no transition (RF4)', (tester) async {
    await pumpMx(
      tester,
      _still(
        Builder(
          builder: (context) => MxButton(
            label: 'Open',
            onPressed: () => showMxDialog<void>(
              context,
              builder: (_) => const MxDialog(title: 'Delete deck?'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(
      tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.byType(MxDialog),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value,
      1,
    );
  });

  testWidgets('the title, the body and the action pair share one 16 edge '
      '(DEV-166)', (tester) async {
    await pumpMx(
      tester,
      MxDialog(
        title: 'Delete deck?',
        body: 'Its cards move to Trash.',
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Delete',
          onConfirm: () {},
        ),
      ),
    );
    final edge = tester.getTopLeft(find.text('Delete deck?')).dx;
    expect(tester.getTopLeft(find.text('Its cards move to Trash.')).dx, edge);
    expect(tester.getTopLeft(find.widgetWithText(MxButton, 'Cancel')).dx, edge);
  });

  // SW-REV-002: showGeneralDialog does not pad for the keyboard, as
  // Material's Dialog does; the dialog must, or its actions sit under it.
  group('the keyboard (SW-REV-002)', () {
    const keyboard = 300.0;
    const screen = Size(360, 640);

    Future<void> openOver(WidgetTester tester, MxDialog dialog) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      showMxDialog<void>(context, builder: (_) => dialog),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    MxSheetActions actions() => MxSheetActions(
      cancelLabel: 'Cancel',
      onCancel: () {},
      confirmLabel: 'Create',
      onConfirm: () {},
    );

    testWidgets('a dialog with a field keeps its actions above the keyboard', (
      tester,
    ) async {
      await openOver(
        tester,
        MxDialog(
          title: 'New deck',
          content: const MxTextField(label: 'Name', hintText: 'Name'),
          actions: actions(),
        ),
      );

      expect(
        tester.getRect(find.text('Create')).bottom,
        lessThanOrEqualTo(screen.height - keyboard),
      );
    });

    testWidgets('a dialog taller than the room left scrolls its text and '
        'keeps its actions in view', (tester) async {
      await openOver(
        tester,
        MxDialog(
          title: 'Reset learning?',
          body: List.filled(
            40,
            'A line that the dialog must scroll.',
          ).join('\n'),
          actions: actions(),
        ),
      );

      expect(
        tester.getRect(find.text('Create')).bottom,
        lessThanOrEqualTo(screen.height - keyboard),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // SW-REV-004: a dialog whose work runs stays open, as MxBottomSheet's
  // isHeld does; a scrim tap goes through maybePop, so one hold covers both.
  testWidgets('isHeld: Back and a scrim tap leave the dialog open', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () => showMxDialog<void>(
            context,
            builder: (_) => const MxDialog(title: 'Delete deck?', isHeld: true),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
  });
}

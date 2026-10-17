import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/forui_expect.dart';
import '../../support/theme_harness.dart';
import '../../support/widget_harness.dart';

final _surfaceFinder = find
    .descendant(
      of: find.byType(MxDialog),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox && widget.decoration is ShapeDecoration,
      ),
    )
    .first;

FDialogStyle _style(WidgetTester tester) =>
    forUiTheme(tester, find.byType(MxDialog)).dialogStyle;

void main() {
  const dimens = AppDimens();

  testWidgets('ForUI\'s dialog surface: the card, its edge and radius', (
    tester,
  ) async {
    await pumpMx(tester, const MxDialog(title: 'Delete deck?'));

    expect(
      tester.widget<DecoratedBox>(_surfaceFinder).decoration,
      _style(tester).decoration,
    );
  });

  testWidgets(
    'width: the column inside ForUI\'s inset, at least 280, capped at '
    '340/320/300',
    (tester) async {
      await pumpMx(tester, const MxDialog(title: 'Delete deck?'));
      final inset = _style(tester).insetPadding.horizontal;
      expect(
        tester.getSize(_surfaceFinder).width,
        (360 - inset).clamp(280.0, 340.0),
      );

      tester.view.physicalSize = const Size(600, 800);
      for (final (width, cap) in [
        (MxDialogWidth.large, 340.0),
        (MxDialogWidth.medium, 320.0),
        (MxDialogWidth.small, 300.0),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await pumpMxAt(tester, MxDialog(title: 'Delete deck?', width: width));

        expect(tester.getSize(_surfaceFinder).width, cap);
      }
    },
  );

  testWidgets(
    'the title over the body 16 below in ForUI\'s dialog text styles, '
    'space24 all round, the text on the action pair\'s edge (DEV-166); the '
    'route is named',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMx(
        tester,
        const MxDialog(title: 'Delete deck?', body: 'Its cards move to Trash.'),
      );
      final surface = tester.getTopLeft(_surfaceFinder);
      final style = _style(tester);

      expect(
        tester.widget<Text>(find.text('Delete deck?')).style,
        style.titleTextStyle,
      );
      expect(
        tester.widget<Text>(find.text('Its cards move to Trash.')).style,
        style.bodyTextStyle,
      );
      expect(
        tester.getTopLeft(find.text('Delete deck?')) - surface,
        Offset(dimens.space24, dimens.space24),
      );
      expect(
        tester.getTopLeft(find.text('Its cards move to Trash.')).dy -
            tester.getBottomLeft(find.text('Delete deck?')).dy,
        dimens.space16,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Delete deck?').first),
        isSemantics(label: 'Delete deck?', namesRoute: true, scopesRoute: true),
      );
      handle.dispose();
    },
  );

  testWidgets('showMxDialog: a scrim tap returns null (RF2)', (tester) async {
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
    expect(find.byType(ModalBarrier), findsWidgets);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(result, isNull);
  });

  testWidgets('showMxDialog returns what the dialog pops with', (tester) async {
    String? result;
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () async => result = await showMxDialog<String>(
            context,
            builder: (dialog) => MxDialog(
              title: 'Pick',
              actions: MxButton(
                label: 'Yes',
                onPressed: () => Navigator.of(dialog).pop('yes'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(result, 'yes');
    expect(find.byType(MxDialog), findsNothing);
  });

  group('motion (RF4)', () {
    Future<void> open(WidgetTester tester) async {
      await pumpMx(
        tester,
        Builder(
          builder: (context) => MxButton(
            label: 'Open',
            onPressed: () => showMxDialog<void>(
              context,
              builder: (_) => const MxDialog(title: 'Delete deck?'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    Finder transitions(Type type) =>
        find.descendant(of: find.byType(MxDialog), matching: find.byType(type));

    testWidgets('it fades and scales in with ForUI\'s motion', (tester) async {
      await open(tester);

      expect(transitions(FadeTransition), findsWidgets);
      expect(transitions(ScaleTransition), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion opens with no transition', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await open(tester);

      expect(transitions(FadeTransition), findsNothing);
      expect(transitions(ScaleTransition), findsNothing);
      expect(find.text('Delete deck?'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('the title, the body and the action pair share one 24 edge, '
      'the pair 24 under the body (DEV-166)', (tester) async {
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
    expect(edge - tester.getTopLeft(_surfaceFinder).dx, 24);
    expect(
      tester.getTopLeft(find.widgetWithText(MxButton, 'Cancel')).dy -
          tester.getBottomLeft(find.text('Its cards move to Trash.')).dy,
      24,
    );
    // The pair is 24 above the dialog's bottom edge too.
    expect(
      tester.getBottomLeft(_surfaceFinder).dy -
          tester.getBottomLeft(find.widgetWithText(MxButton, 'Cancel')).dy,
      24,
    );
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
          theme: materialHostTheme(buildLightTheme()),
          builder: mxThemeBuilder(buildLightTheme()),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: MxButton(
                  label: 'Open',
                  onPressed: () =>
                      showMxDialog<void>(context, builder: (_) => dialog),
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

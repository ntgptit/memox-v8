import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

final _surfaceFinder = find
    .descendant(of: find.byType(MxDialog), matching: find.byType(Material))
    .first;

Material _surface(WidgetTester tester) =>
    tester.widget<Material>(_surfaceFinder);

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final scheme = lightColorScheme;

  testWidgets('the high container at radiusXl, elevation 6 with no shadow', (
    tester,
  ) async {
    await pumpMx(tester, const MxDialog(title: 'Delete deck?'));

    expect(_surface(tester).color, scheme.surfaceContainerHigh);
    expect(
      (_surface(tester).shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(const AppDimens().radiusXl),
    );
    expect(_surface(tester).elevation, 6);
    expect(_surface(tester).shadowColor, Colors.transparent);
  });

  testWidgets(
    'width: the column space24 in from each edge, capped at 340/320/300',
    (tester) async {
      await pumpMx(tester, const MxDialog(title: 'Delete deck?'));
      expect(
        tester.getSize(find.byType(Material).last).width,
        360 - 2 * const AppDimens().space24,
      );

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
    },
  );

  testWidgets(
    'headlineSmall over a bodyMedium body 16 below, space24 all round, the '
    'text on the action pair\'s edge (DEV-166); the route is named',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMx(
        tester,
        const MxDialog(title: 'Delete deck?', body: 'Its cards move to Trash.'),
      );
      final surface = tester.getTopLeft(find.byType(Material).last);

      final title = tester.widget<Text>(find.text('Delete deck?')).style!;
      final body = tester.widget<Text>(find.text('Its cards move to Trash.'));
      final texts = tester.element(find.text('Delete deck?')).texts;
      expect(
        (title.fontSize, title.height, title.color),
        (
          texts.termCompact.fontSize,
          texts.termCompact.height,
          scheme.onSurface,
        ),
      );
      expect(
        (body.style!.fontSize, body.style!.color),
        (texts.body.fontSize, scheme.onSurfaceVariant),
      );
      expect(
        tester.getTopLeft(find.text('Delete deck?')) - surface,
        Offset(const AppDimens().space24, const AppDimens().space24),
      );
      expect(
        tester.getTopLeft(find.text('Its cards move to Trash.')).dy -
            tester.getBottomLeft(find.text('Delete deck?')).dy,
        const AppDimens().space16,
      );
      expect(
        tester.getSemantics(find.byType(MxDialog)),
        isSemantics(label: 'Delete deck?', namesRoute: true, scopesRoute: true),
      );
      handle.dispose();
    },
  );

  testWidgets('showMxDialog: the theme\'s scrim; a scrim tap returns null '
      '(RF2)', (tester) async {
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
      scheme.scrim.withValues(alpha: const AppDimens().opacityScrim),
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

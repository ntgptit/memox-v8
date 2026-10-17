import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = lightColorScheme;

  testWidgets('a floating inverse toast: radiusXs, 16 sides', (tester) async {
    late SnackBar bar;
    late SnackBarThemeData theme;
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          bar = buildMxSnackBar(context, message: 'Saved');
          theme = Theme.of(context).snackBarTheme;
          return const SizedBox();
        },
      ),
    );

    // The toast's surface comes from the theme (spec §4.6).
    expect(bar.backgroundColor ?? theme.backgroundColor, scheme.inverseSurface);
    expect(bar.behavior ?? theme.behavior, SnackBarBehavior.floating);
    expect(
      ((bar.shape ?? theme.shape)! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(const AppDimens().radiusXs),
    );
    expect(
      bar.margin ?? theme.insetPadding,
      const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
    // The message carries the 14 vertical padding itself.
    expect(bar.padding, const EdgeInsets.symmetric(horizontal: 16));
  });

  testWidgets(
    'bodyMedium message on the inverse surface; a small action in the control box',
    (tester) async {
      await pumpMx(
        tester,
        SizedBox(
          width: 328,
          child: MxSnackbarContent(
            message: 'Moved to Trash',
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
      );
      final message = tester.widget<Text>(find.text('Moved to Trash')).style!;
      final painted = find.descendant(
        of: find.byType(TextButton),
        matching: find.byType(Material),
      );

      final role = tester
          .element(find.text('Moved to Trash'))
          .texts
          .bodyMedium!;
      expect((message.fontSize, message.height), (role.fontSize, role.height));
      expect(message.color, scheme.onInverseSurface);
      expect(
        tester.getSize(painted.first).height,
        const AppDimens().sizeButtonSmall,
      );
      expect(
        tester.getTopLeft(find.byType(TextButton)).dx -
            tester.getTopRight(find.text('Moved to Trash')).dx,
        12,
      );
      await expectAccessibleTargets(tester);
    },
  );

  testWidgets('in the platform SnackBar a message alone spans the toast', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => buildMxSnackBar(
          context,
          message: 'Deck saved',
        ).withAnimation(kAlwaysCompleteAnimation),
      ),
    );

    // The SDK puts the content in an Expanded: the phone's 360 less the
    // theme's 16 on each side, less the toast's own 16 on each side.
    final toast = tester.getRect(find.byType(Material).last);
    final content = tester.getRect(find.byType(MxSnackbarContent));
    expect(toast.width, 360 - 2 * 16);
    expect(content.left - toast.left, 16);
    expect(toast.right - content.right, 16);
  });

  testWidgets('a message alone has 14 above and below its line', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(width: 328, child: MxSnackbarContent(message: 'Saved')),
    );
    final message = tester.getRect(find.text('Saved'));
    final content = tester.getRect(find.byType(MxSnackbarContent));

    expect(message.top - content.top, 14);
    expect(content.bottom - message.bottom, 14);
  });

  group('an action wider than 25% of the toast goes on its own line', () {
    // The toast is the content (328) and its 16 sides: 360 wide.
    Future<void> pumpAction(WidgetTester tester, String label) => pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSnackbarContent(
          message: 'Moved to Trash',
          actionLabel: label,
          onAction: () {},
        ),
      ),
    );

    testWidgets('a short label stays beside the message', (tester) async {
      await pumpAction(tester, 'Undo');

      expect(
        tester.getCenter(find.byType(TextButton)).dy,
        tester.getCenter(find.text('Moved to Trash')).dy,
      );
    });

    testWidgets('a long label drops under the message, at the end', (
      tester,
    ) async {
      await pumpAction(tester, 'Open the trash');
      final button = tester.getRect(find.byType(TextButton));
      final message = tester.getRect(find.text('Moved to Trash'));

      expect(button.top, greaterThanOrEqualTo(message.bottom));
      expect(
        button.right,
        tester.getRect(find.byType(MxSnackbarContent)).right,
      );
      expect(
        message.top - tester.getRect(find.byType(MxSnackbarContent)).top,
        14,
      );
      await expectAccessibleTargets(tester);
    });
  });

  testWidgets('the action\'s focus ring is inversePrimary on the toast', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSnackbarContent(
          message: 'Moved to Trash',
          actionLabel: 'Undo',
          onAction: () {},
        ),
      ),
    );
    final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
    final focused =
        style.shape!.resolve({WidgetState.focused})! as MxFocusRingBorder;

    expect(focused.ring.color, scheme.inversePrimary);
  });

  testWidgets('Undo hides the toast and calls onAction once (RF5)', (
    tester,
  ) async {
    var undos = 0;
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Delete',
          onPressed: () => showMxSnackbar(
            context,
            message: 'Moved to Trash',
            actionLabel: 'Undo',
            onAction: () => undos++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Moved to Trash'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undos, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a toast with an action stays 48 tall', (tester) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Delete',
          onPressed: () => showMxSnackbar(
            context,
            message: 'Moved to Trash',
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // The action's 48 target sits inside the toast instead of adding the
    // message's 14 + 14 around it.
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(SnackBar),
                  matching: find.byType(Material),
                )
                .first,
          )
          .height,
      48,
    );
  });

  testWidgets('a long message wraps; the action keeps its width (RF5)', (
    tester,
  ) async {
    Future<void> pumpMessage(String message) => pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSnackbarContent(
          message: message,
          actionLabel: 'Undo',
          onAction: () {},
        ),
      ),
    );

    await pumpMessage('Saved');
    final action = tester.getSize(find.byType(TextButton)).width;
    final oneLine = tester.getSize(find.text('Saved')).height;

    final long = List.filled(10, 'Moved to Trash').join(' ');
    await pumpMessage(long);
    expect(tester.getSize(find.byType(TextButton)).width, action);
    expect(tester.getSize(find.text(long)).height, greaterThan(oneLine));
  });

  Future<void> pumpToasts(
    WidgetTester tester,
    List<({String message, bool hasUndo})> toasts, {
    Duration duration = const Duration(seconds: 8),
  }) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final toast in toasts)
              MxButton(
                label: 'Show ${toast.message}',
                onPressed: () => showMxSnackbar(
                  context,
                  message: toast.message,
                  actionLabel: toast.hasUndo ? 'Undo' : null,
                  onAction: toast.hasUndo ? () {} : null,
                  duration: duration,
                ),
              ),
          ],
        ),
      ),
    );
  }

  testWidgets('a toast stays its duration, then goes (FE-B1 D3)', (
    tester,
  ) async {
    await pumpToasts(tester, [(message: 'Moved to Trash', hasUndo: true)]);
    await tester.tap(find.text('Show Moved to Trash'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 7));
    expect(find.text('Moved to Trash'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('under TalkBack a toast with an action stays (FE-B1 D14)', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpToasts(tester, [
      (message: 'Moved to Trash', hasUndo: true),
      (message: 'Saved', hasUndo: false),
    ]);

    await tester.tap(find.text('Show Moved to Trash'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Moved to Trash'), findsOneWidget);

    // One without an action still goes.
    await tester.tap(find.text('Show Saved'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a new toast replaces the one on screen (FE-B1 D14)', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpToasts(tester, [
      (message: 'Moved to Trash', hasUndo: true),
      (message: 'Saved', hasUndo: false),
    ]);

    await tester.tap(find.text('Show Moved to Trash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Moved to Trash'), findsNothing);
    expect(find.text('Saved'), findsOneWidget);
  });

  test('actionLabel and onAction come together', () {
    expect(
      () => MxSnackbarContent(message: 'Saved', actionLabel: 'Undo'),
      throwsAssertionError,
    );
  });

  group('width (FE-C5 D5)', () {
    Widget trigger() => Builder(
      builder: (context) => MxButton(
        label: 'Save',
        onPressed: () => showMxSnackbar(context, message: 'Saved'),
      ),
    );
    Rect toast(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );

    testWidgets('a wide window: at most the column, centred', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpMxAt(tester, trigger());
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final rect = toast(tester);
      const dimens = AppDimens();
      final width = dimens.sizeContentMax - 2 * dimens.space16;
      expect((rect.left, rect.width), ((1280 - width) / 2, width));
    });

    testWidgets('a phone: the theme inset, as before', (tester) async {
      await pumpMx(tester, trigger());
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final rect = toast(tester);
      expect((rect.left, rect.width), (16, 360 - 2 * 16));
    });
  });
}

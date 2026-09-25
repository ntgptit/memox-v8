import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('a floating inverse toast: radius 12, 16 sides', (tester) async {
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
      BorderRadius.circular(12),
    );
    expect(
      bar.margin ?? theme.insetPadding,
      const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
    // The message carries the 10 vertical padding itself.
    expect(bar.padding, const EdgeInsets.symmetric(horizontal: 16));
  });

  testWidgets('14 message on the inverse surface; a 32 action in 48', (
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
    final message = tester.widget<Text>(find.text('Moved to Trash')).style!;
    final painted = find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    );

    expect((message.fontSize, message.height), (14, 1.4));
    expect(message.color, scheme.onInverseSurface);
    expect(tester.getSize(painted.first).height, 32);
    expect(
      tester.getTopLeft(find.byType(TextButton)).dx -
          tester.getTopRight(find.text('Moved to Trash')).dx,
      12,
    );
    await expectAccessibleTargets(tester);
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
    // message's 10 + 10 around it.
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

  test('actionLabel and onAction come together', () {
    expect(
      () => MxSnackbarContent(message: 'Saved', actionLabel: 'Undo'),
      throwsAssertionError,
    );
  });
}

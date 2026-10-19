import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import '../../support/widget_harness.dart';

// A toast's action reads the screen that showed it, so an actionable toast
// leaves with that screen's route; one shown from above the routes, as Undo
// is, outlives them (closing acceptance 2026-10-18 NEW-1).

final _toast = find.byType(FToast);

/// A page that shows a toast from its own context, or from the root
/// navigator's when [fromRoot].
Widget _page({required bool hasAction, bool fromRoot = false}) => Builder(
  builder: (context) => MxButton(
    label: 'Show',
    onPressed: () => showMxSnackbar(
      fromRoot ? Navigator.of(context, rootNavigator: true).context : context,
      message: 'Couldn’t save',
      actionLabel: hasAction ? 'Retry' : null,
      onAction: hasAction ? () {} : null,
    ),
  ),
);

Future<void> _openAndShow(WidgetTester tester, Widget page) async {
  await pumpMx(
    tester,
    Builder(
      builder: (context) => MxButton(
        label: 'Open',
        onPressed: () => unawaited(
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => page)),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();
  expect(_toast, findsOneWidget);
}

Future<void> _leave(WidgetTester tester) async {
  unawaited(
    tester.state<NavigatorState>(find.byType(Navigator).last).maybePop(),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an actionable toast leaves with the screen that showed it', (
    tester,
  ) async {
    await _openAndShow(tester, _page(hasAction: true));

    await _leave(tester);

    expect(find.text('Show'), findsNothing);
    expect(_toast, findsNothing);
  });

  testWidgets('a toast with no action stays when its screen leaves: it only '
      'says what happened', (tester) async {
    await _openAndShow(tester, _page(hasAction: false));

    await _leave(tester);

    expect(_toast, findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a toast shown from above the routes outlives them, as Undo '
      'does', (tester) async {
    await _openAndShow(tester, _page(hasAction: true, fromRoot: true));

    await _leave(tester);

    expect(_toast, findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}

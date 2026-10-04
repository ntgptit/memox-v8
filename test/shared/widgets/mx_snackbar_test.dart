import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import 'support/mx_harness.dart';

Widget _trigger({
  String? action,
  VoidCallback? onAction,
  bool isUndo = false,
}) => Builder(
  builder: (context) => TextButton(
    onPressed: () => showMxSnackbar(
      context,
      message: 'Deck moved to Trash',
      actionLabel: action,
      onAction: onAction,
      isUndo: isUndo,
    ),
    child: const Text('Go'),
  ),
);

void main() {
  testWidgets('a message stays 4s', (tester) async {
    await pumpMx(tester, _trigger());
    await tester.tap(find.text('Go'));
    await tester.pump();
    final SnackBar bar = tester.widget(find.byType(SnackBar));
    expect(bar.duration, AppDurations.toast);
    expect(find.text('Deck moved to Trash'), findsOneWidget);
  });

  testWidgets('Undo stays 8s, reads in inverse-primary and closes it', (
    tester,
  ) async {
    var undone = 0;
    await pumpMx(
      tester,
      _trigger(action: 'Undo', onAction: () => undone++, isUndo: true),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    final SnackBar bar = tester.widget(find.byType(SnackBar));
    expect(bar.duration, AppDurations.toastWithUndo);
    final MxButton undo = tester.widget(find.byType(MxButton));
    expect(undo.tone, MxButtonTone.inverse);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('with TalkBack on, an action keeps it up', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: Scaffold(
            body: _trigger(action: 'Undo', onAction: () {}, isUndo: true),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isTrue);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  late bool? answer;

  Widget host({bool canConfirm = true}) => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => unawaited(
          confirmAccountStep(
            context,
            title: 'Sure?',
            body: 'Body',
            confirmLabel: 'Do it',
            isDestructive: true,
            canConfirm: canConfirm,
          ).then((value) => answer = value),
        ),
        child: const Text('ask'),
      ),
    ),
  );

  setUp(() => answer = null);

  libraryTest('the confirm answers yes, Cancel no', (tester, env) async {
    await pumpLibraryScreen(tester, env, host());
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    expect(find.text('Sure?'), findsOneWidget);
    await tester.tap(find.text('Do it'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);

    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });

  libraryTest('a confirm that cannot go is disabled', (tester, env) async {
    await pumpLibraryScreen(tester, env, host(canConfirm: false));
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();

    final confirm = tester.widget<MxButton>(
      find.widgetWithText(MxButton, 'Do it'),
    );
    expect(confirm.onPressed, isNull);
    expect(confirm.tone, MxButtonTone.destructive);
  });

  libraryTest('the last-admin dialog explains and closes on OK', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(showLastAdminDialog(context)),
            child: const Text('refuse'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('refuse'));
    await tester.pumpAndSettle();
    expect(find.text(_en.accountLastAdminTitle), findsOneWidget);
    expect(find.text(_en.accountLastAdmin), findsOneWidget);

    await tester.tap(find.text(_en.commonOk));
    await tester.pumpAndSettle();
    expect(find.text(_en.accountLastAdminTitle), findsNothing);
  });
}

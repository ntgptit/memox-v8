import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

MxButton _button(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

// Audit 2026-10-17 findings on screen 30: the starting account, the leave
// question asked once, and a declined loss after the form is gone.
void main() {
  late List<String> codesSent;

  SignInScreen screen() =>
      SignInScreen(onCodeSent: codesSent.add, onSignedIn: () {});

  SignInScreen reauth() => SignInScreen(
    purpose: SignInPurpose.reauth,
    onCodeSent: codesSent.add,
    onSignedIn: () {},
    onLeftAccount: () {},
  );

  setUp(() => codesSent = []);

  accountTest('while the account starts, the form waits without an offline '
      'note (audit 2026-10-17 ACC-2)', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        authStateOf(const Bootstrapping()),
      ],
    );

    expect(_button(tester, _en.accountSendCode).onPressed, isNull);
    expect(_button(tester, _en.accountContinueGoogle).onPressed, isNull);
    expect(find.text(_en.accountOfflineNote), findsNothing);
  });

  accountTest('two quick taps on Continue without an account open one '
      'dialog (audit 2026-10-17 ACC-4)', (tester, env, world) async {
    await refuseSession(world);
    await pumpLibraryScreen(
      tester,
      env,
      reauth(),
      overrides: accountOverrides(world),
    );

    // Both presses land before the first dialog is up to cover the page.
    final press = _button(tester, _en.accountContinueWithoutThis).onPressed!;
    press();
    press();
    await _settle(tester);

    expect(find.byType(MxDialog), findsOneWidget);
  });

  accountTest('declining the loss after the form is gone reaches nothing '
      'disposed, and still drops the picked Google account (audit '
      '2026-10-17 ACC-5)', (tester, env, world) async {
    await refuseSession(world);
    world.gateway.google = const GoogleCredential(
      idToken: 'other',
      email: 'other@example.com',
    );
    final shown = ValueNotifier<bool>(true);
    addTearDown(shown.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      ValueListenableBuilder<bool>(
        valueListenable: shown,
        builder: (_, isShown, _) =>
            isShown ? reauth() : const Scaffold(body: SizedBox.shrink()),
      ),
      overrides: accountOverrides(world),
    );
    await _settle(tester);

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);
    expect(find.text(_en.accountUnsentTitle(2)), findsOneWidget);
    shown.value = false;
    await tester.pump();
    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(_en.accountUnsentTitle(2)), findsNothing);
  });
}

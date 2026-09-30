import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/account_harness.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

MxButton _button(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

void main() {
  late List<String> codesSent;
  late int signIns;

  SignInScreen screen() =>
      SignInScreen(onCodeSent: codesSent.add, onSignedIn: () => signIns++);

  setUp(() {
    codesSent = [];
    signIns = 0;
  });

  accountTest('an address gets a code, and the code screen is next', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(codesSent, ['a@example.com']);
  });

  accountTest('a mistyped address is said under the field, and nothing is '
      'sent', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.text(_en.accountEmailInvalid), findsOneWidget);
    expect(codesSent, isEmpty);
    expect(world.server.sentCodes, isEmpty);
  });

  accountTest('Google attaches the account, says so and leaves', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);

    expect(signIns, 1);
    expect(find.text(_en.accountSignedInAs('g@example.com')), findsOneWidget);
  });

  accountTest("another account's address asks to merge", (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: 'b@example.com');
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'b@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.byType(MergeChoiceSheetWidget), findsOneWidget);
  });

  accountTest('offline says that nothing changed', (tester, env, world) async {
    world.network.goOffline();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.text(_en.accountOffline), findsOneWidget);
  });

  accountTest('not ready to link: the form waits and says why', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), authStateOf(const LocalOnly())],
    );

    expect(_button(tester, _en.accountSendCode).onPressed, isNull);
    expect(_button(tester, _en.accountContinueGoogle).onPressed, isNull);
    expect(find.text(_en.accountOfflineNote), findsOneWidget);
  });

  group('reauth', () {
    late int left;

    setUp(() => left = 0);

    SignInScreen reauth() => SignInScreen(
      purpose: SignInPurpose.reauth,
      onCodeSent: codesSent.add,
      onSignedIn: () => signIns++,
      onLeftAccount: () => left++,
    );

    accountTest('the reauth line, and the last address filled in', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      expect(find.text(_en.accountReauthLine), findsOneWidget);
      expect(find.text('a@example.com'), findsOneWidget);
      expect(_button(tester, _en.accountSendCode).onPressed, isNotNull);
    });

    accountTest('another address with changes unsent asks, then sends', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      await tester.enterText(find.byType(TextField), 'b@example.com');
      await tester.tap(find.text(_en.accountSendCode));
      await _settle(tester);
      expect(find.text(_en.accountUnsentTitle(2)), findsOneWidget);

      await tester.tap(find.widgetWithText(MxButton, _en.accountContinue));
      await _settle(tester);
      expect(codesSent, ['b@example.com']);
    });

    accountTest('Continue without an account asks, then leaves the account', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      await tester.tap(find.text(_en.accountContinueWithout));
      await _settle(tester);
      expect(
        find.text(_en.accountWithoutBody('a@example.com')),
        findsOneWidget,
      );
      // The dialog's confirm, not the screen's button of the same name.
      await tester.tap(
        find.descendant(
          of: find.byType(MxDialog),
          matching: find.widgetWithText(MxButton, _en.accountContinueWithout),
        ),
      );
      await _settle(tester);

      expect(left, 1);
      expect(world.state, isNot(isA<ReauthRequired>()));
    });
  });
}

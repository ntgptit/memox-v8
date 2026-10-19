import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

// The address field declares the Send action (sign_in_form_widget.dart): the
// keyboard's action does what the Send code button does.
void main() {
  late List<String> codesSent;

  SignInScreen screen() =>
      SignInScreen(onCodeSent: codesSent.add, onSignedIn: () {});

  setUp(() => codesSent = []);

  accountTest('the keyboard Send action sends the code, as Send code does', (
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

    await tester.enterText(find.byType(FTextField), '  a@example.com  ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await _settle(tester);

    expect(codesSent, ['a@example.com']);
    expect(world.server.sentCodes, hasLength(1));
  });

  accountTest('the keyboard Send action on a non-address is refused under the '
      'field, and nothing is sent', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(FTextField), 'a@');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await _settle(tester);

    expect(find.text(_en.accountEmailInvalid), findsOneWidget);
    expect(codesSent, isEmpty);
    expect(world.server.sentCodes, isEmpty);
  });

  accountTest('the keyboard Send action on an empty field is refused like the '
      'button, and nothing is sent', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.testTextInput.receiveAction(TextInputAction.send);
    await _settle(tester);

    expect(find.text(_en.accountEmailInvalid), findsOneWidget);
    expect(codesSent, isEmpty);
    expect(world.server.sentCodes, isEmpty);
  });

  accountTest('while the account starts, the keyboard Send action does '
      'nothing, as the button does', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        authStateOf(const Bootstrapping()),
      ],
    );

    await tester.enterText(find.byType(FTextField), 'a@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await _settle(tester);

    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, _en.accountSendCode))
          .onPressed,
      isNull,
    );
    expect(codesSent, isEmpty);
    expect(world.server.sentCodes, isEmpty);
  });
}

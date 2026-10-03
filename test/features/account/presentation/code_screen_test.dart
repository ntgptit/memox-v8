import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/code_form_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/account_harness.dart';
import '../../../support/fake_auth_server.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late int signIns;

  setUp(() => signIns = 0);

  CodeScreen screen() =>
      CodeScreen(email: 'a@example.com', onSignedIn: () => signIns++);

  accountTest('six digits sign in and say so', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    expect(find.text(_en.accountCodeSentTo('a@example.com')), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await _settle(tester);

    expect(signIns, 1);
    expect(find.text(_en.accountSignedInAs('a@example.com')), findsOneWidget);
  });

  accountTest('a wrong code clears the field and says so; the right one then '
      'signs in (Review Focus 4)', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), '000000');
    await _settle(tester);

    expect(find.text(_en.accountCodeWrong), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(signIns, 0);

    await tester.enterText(find.byType(TextField), '123456');
    await _settle(tester);
    expect(signIns, 1);
  });

  accountTest('Resend waits a minute, then sends a new code and waits again', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    final waiting = find.widgetWithText(MxButton, _en.accountResendIn('1:00'));
    expect(tester.widget<MxButton>(waiting).onPressed, isNull);

    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);

    expect(find.text(_en.accountCodeResent), findsOneWidget);
    expect(find.text(_en.accountResendIn('1:00')), findsOneWidget);
  });

  accountTest('a re-auth resend to another address names the unsent '
      'changes again (P3b minor M7)', (tester, env, world) async {
    await refuseSession(world);
    await world.coordinator.requestCode('b@example.com', confirmedLoss: true);
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CodeFormWidget(
          email: 'b@example.com',
          purpose: SignInPurpose.reauth,
          onUseAnotherEmail: () {},
          onSignedIn: () {},
        ),
      ),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));

    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);
    expect(find.text(_en.accountUnsentTitle(2)), findsOneWidget);
    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);
    expect(find.text(_en.accountCodeResent), findsNothing);

    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);
    await tester.tap(find.widgetWithText(MxButton, _en.accountContinue));
    await _settle(tester);
    expect(find.text(_en.accountCodeResent), findsOneWidget);
  });

  accountTest('a re-auth resend to its own address asks nothing', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CodeFormWidget(
          email: 'a@example.com',
          purpose: SignInPurpose.reauth,
          onUseAnotherEmail: () {},
          onSignedIn: () {},
        ),
      ),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));

    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);

    expect(find.text(_en.accountUnsentTitle(2)), findsNothing);
    expect(find.text(_en.accountCodeResent), findsOneWidget);
  });

  accountTest('a code typed while a new one is on its way is kept and '
      'checked', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));
    final held = world.gateway.holdRequests = Completer<void>();
    await tester.tap(find.text(_en.accountResend));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    await _settle(tester);

    expect(signIns, 1);
  });

  accountTest('after a wrong code the field keeps the keyboard', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), '000000');
    await _settle(tester);

    expect(find.text(_en.accountCodeWrong), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  accountTest('the field takes the keyboard when the step opens (2.45)', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  accountTest('the field stays enabled while the code is checked (2.45)', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    final held = world.gateway.holdVerifies = Completer<void>();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

    held.complete();
    world.gateway.holdVerifies = null;
    await _settle(tester);
    expect(signIns, 1);
  });

  accountTest('offline keeps the six digits and says so; Retry checks them '
      'again (2.45)', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    world.network.goOffline();

    await tester.enterText(find.byType(TextField), '123456');
    await _settle(tester);

    expect(find.text(_en.accountOffline), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '123456',
    );
    // Offline warns too: a failure that asks the person to retry (owner).
    expect(
      tester.widget<MxInlineBanner>(find.byType(MxInlineBanner)).tone,
      MxBannerTone.warning,
    );
    expect(signIns, 0);

    world.network.goOnline();
    await tester.pump();
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(signIns, 1);
    expect(find.text(_en.accountOffline), findsNothing);
  });

  accountTest('Retry with a digit missing focuses the field instead of '
      'checking (2.45)', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    world.network.goOffline();
    await tester.enterText(find.byType(TextField), '123456');
    await _settle(tester);

    await tester.enterText(find.byType(TextField), '12345');
    world.network.goOnline();
    await tester.pump();
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(signIns, 0, reason: 'five digits are not a code');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  accountTest('a re-auth code signs in again', (tester, env, world) async {
    await refuseSession(world);
    await world.coordinator.requestCode('a@example.com');
    var signedIn = 0;
    await pumpLibraryScreen(
      tester,
      env,
      CodeScreen(
        email: 'a@example.com',
        purpose: SignInPurpose.reauth,
        onSignedIn: () => signedIn++,
      ),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(signedIn, 1);
    expect(world.state, isA<Ready>());
  });

  accountTest('a sign-in that worked but is not confirmed yet still says '
      '"Signed in" (P3b minor M2, final review I1)', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await world.coordinator.requestCode('a@example.com');
    // Signed in, then `me()` meets no network: the state stays Validating.
    world.gateway.afterSignIn = () => world.server.offline = true;
    await pumpLibraryScreen(
      tester,
      env,
      const CodeScreen(
        email: 'a@example.com',
        purpose: SignInPurpose.reauth,
        onSignedIn: _noop,
      ),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(world.state, isA<Validating>());
    expect(find.text(_en.accountSignedIn), findsOneWidget);
  });

  accountTest('a re-auth into another account that stops on the way says '
      'no "Signed in"; the layer says what happened (P3b minor M2)', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await world.coordinator.requestCode('b@example.com', confirmedLoss: true);
    // The switch that follows the sign-in meets no network.
    world.gateway.afterSignIn = () => world.server.offline = true;
    await pumpLibraryScreen(
      tester,
      env,
      const CodeScreen(
        email: 'b@example.com',
        purpose: SignInPurpose.reauth,
        onSignedIn: _noop,
      ),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(world.state, isNot(isA<Ready>()));
    expect(find.text(_en.accountSignedIn), findsNothing);
    expect(find.text(_en.accountSignedInAs('b@example.com')), findsNothing);
  });
}

void _noop() {}

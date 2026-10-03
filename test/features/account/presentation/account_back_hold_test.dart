import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

// SP2b 2.46: while a sign-in command runs, Back waits, so its result has a
// screen to land on.
void main() {
  accountTest('Welcome: Back waits while Google signs in, then leaves the app '
      'again', (tester, env, world) async {
    final closes = watchAppCloses(tester);
    await pumpLibraryScreen(
      tester,
      env,
      WelcomeScreen(onDone: () {}, onEmail: () {}),
      overrides: accountOverrides(world),
    );
    final held = world.gateway.holdRequests = Completer<void>();
    await tester.tap(find.text(_en.accountContinueGoogle));
    await tester.pump();

    await tester.binding.handlePopRoute();
    expect(closes, isEmpty);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    await tester.binding.handlePopRoute();
    expect(closes, hasLength(1));
  });

  accountTest('screen 30: Back and the app bar arrow wait while a code is '
      'sent', (tester, env, world) async {
    await pumpLibraryScreenPushed(
      tester,
      env,
      SignInScreen(onCodeSent: (_) {}, onSignedIn: () {}),
      overrides: accountOverrides(world),
    );
    final held = world.gateway.holdRequests = Completer<void>();
    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.back));
    await _settle(tester);
    expect(find.byType(SignInScreen), findsOneWidget);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsNothing);
  });

  accountTest('screen 31: Back waits while the code is checked', (
    tester,
    env,
    world,
  ) async {
    var signIns = 0;
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreenPushed(
      tester,
      env,
      CodeScreen(email: 'a@example.com', onSignedIn: () => signIns++),
      overrides: accountOverrides(world),
    );
    final held = world.gateway.holdVerifies = Completer<void>();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.back));
    await _settle(tester);
    expect(find.byType(CodeScreen), findsOneWidget);

    held.complete();
    world.gateway.holdVerifies = null;
    await _settle(tester);
    expect(signIns, 1);
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(find.byType(CodeScreen), findsNothing);
  });

  accountTest('screen 31: Back waits while a new code is requested', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreenPushed(
      tester,
      env,
      CodeScreen(email: 'a@example.com', onSignedIn: () {}),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));
    final held = world.gateway.holdRequests = Completer<void>();
    await tester.tap(find.text(_en.accountResend));
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.back));
    await _settle(tester);
    expect(find.byType(CodeScreen), findsOneWidget);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(find.byType(CodeScreen), findsNothing);
  });
}

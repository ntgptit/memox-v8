import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/features/account/presentation/screens/account_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../support/account_harness.dart';
import '../support/fake_auth_server.dart';
import '../support/library_harness.dart';

// Where the sign-in flows begin and end (login navigation review,
// owner 2026-10-08): Welcome's email ends where Welcome was headed, as its
// Google does; the layer's Cancel waits while its target signs in.

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  final welcomeShown = welcomeDueProvider.overrideWithBuild((ref, _) => true);

  accountTest("Welcome's email opens the sign-in over where the launch was "
      'headed, and Back returns there', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [...accountOverrides(world), welcomeShown],
    );
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text(_en.accountContinueEmail));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(DeckLevelScreen), findsOneWidget);
  });

  accountTest("Welcome's email, its code, and the flow ends where the launch "
      'was headed, saying who signed in', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [...accountOverrides(world), welcomeShown],
    );
    await tester.tap(find.text(_en.accountContinueEmail));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, FakeAuthGateway.code);
    await _settle(tester);

    expect(world.state, isA<Ready>());
    expect(find.byType(AccountScreen), findsNothing);
    expect(find.byType(DeckLevelScreen), findsOneWidget);
    expect(find.text(_en.accountSignedInAs('a@example.com')), findsOneWidget);
  });

  accountTest("the layer's Cancel and Back wait while its target signs in, "
      'so a switch is never cancelled behind a sign-in that goes on', (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: world.gateway.google.email);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .go(AppRoutes.settings);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.accountSignIn));
    await _settle(tester);

    final held = world.gateway.holdGoogleSignIn = Completer<void>();
    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);

    final cancel = find.descendant(
      of: find.byType(AccountTransitionLayerWidget),
      matching: find.widgetWithText(MxButton, _en.commonCancel),
    );
    expect(cancel, findsOneWidget);
    expect(tester.widget<MxButton>(cancel).onPressed, isNull);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(world.state, isA<Transitioning>());

    world.gateway.holdGoogleSignIn = null;
    held.complete();
    await tester.pumpAndSettle();
    expect(world.state, isA<Ready>());
  });
}

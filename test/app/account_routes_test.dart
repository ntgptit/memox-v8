import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/presentation/screens/account_screen.dart';
import 'package:memox/features/account/presentation/screens/users_screen.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/features/settings/presentation/screens/admin_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../support/account_harness.dart';
import '../support/fake_auth_server.dart';
import '../support/library_harness.dart';
import '../support/users_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

void main() {
  accountTest('Welcome takes the launch while it is due, and Continue '
      'without an account lands where it was headed', (
    tester,
    env,
    world,
  ) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        welcomeDueProvider.overrideWithBuild((ref, _) => true),
      ],
    );

    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.tap(find.text(_en.accountContinueWithout));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(DeckLevelScreen), findsOneWidget);
    expect(await AccountDeviceRepositoryImpl(env.db).isWelcomeSeen(), isTrue);
  });

  accountTest('a deep link while Welcome is due returns there after it '
      '(Review Focus 5)', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        welcomeDueProvider.overrideWithBuild((ref, _) => true),
      ],
    );

    _router(tester).go(AppRoutes.progress);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text(_en.accountContinueWithout));
    await tester.pumpAndSettle();
    expect(
      _router(tester).routeInformationProvider.value.uri.path,
      AppRoutes.progress,
    );
  });

  accountTest('Settings › Sign in, the code, and the flow ends on screen 32 '
      'showing the account (P3b B9)', (tester, env, world) async {
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    await tester.tap(
      find.descendant(
        of: find.byType(MxBottomNav),
        matching: find.text(_en.navSettings),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.accountSignIn));
    await _settle(tester);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);
    expect(find.byType(CodeScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await _settle(tester);
    await _settle(tester);

    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.byType(CodeScreen), findsNothing);
    expect(find.text('a@example.com'), findsOneWidget);
  });

  accountTest('the attach flow is closed to a device that holds an account', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));

    _router(tester).go(AppRoutes.settingsSignInLink);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(AccountScreen), findsOneWidget);
  });

  accountTest('Settings › the account row opens screen 32; Back returns', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();

    await tester.tap(find.text('a@example.com'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  accountTest('a re-auth from Study home returns to Study home (P3b B9)', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.study);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    await tester.tap(find.text(_en.accountSendCode)); // the address is filled
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pumpAndSettle();

    expect(
      _router(tester).routeInformationProvider.value.uri.path,
      AppRoutes.study,
    );
    expect(world.state, isA<Ready>());
  });

  test('only a location inside the app is a way back (P3b minor M1)', () {
    for (final inside in ['/study', '/settings/account', '/decks?x=1']) {
      expect(AppRoutes.inAppOr(inside, AppRoutes.decks), inside);
    }
    for (final outside in [
      null,
      '',
      'study',
      '//evil.example/x',
      'https://evil.example/x',
      'memox://app/study',
      '/\\evil.example',
    ]) {
      expect(AppRoutes.inAppOr(outside, AppRoutes.decks), AppRoutes.decks);
    }
  });

  accountTest('Welcome goes on to its fallback when `from` leaves the app '
      '(P3b minor M1)', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        welcomeDueProvider.overrideWithBuild((ref, _) => true),
      ],
    );

    _router(tester).go(AppRoutes.welcomeFrom('https://evil.example/study'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.accountContinueWithout));
    await tester.pumpAndSettle();

    expect(
      _router(tester).routeInformationProvider.value.uri.toString(),
      AppRoutes.decks,
    );
  });

  accountTest('a re-auth whose `from` leaves the app ends on Settings '
      '(P3b minor M1)', (tester, env, world) async {
    await refuseSession(world);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester)
        .go(AppRoutes.settingsSignInReauth(from: '//evil.example/study'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.accountSendCode));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pumpAndSettle();

    expect(
      _router(tester).routeInformationProvider.value.uri.toString(),
      AppRoutes.settings,
    );
    expect(world.state, isA<Ready>());
  });

  accountTest('signing out from screen 32 lands on Settings', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    world.device.pending = 0;
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.settingsAccount);
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.accountSignOut));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.widgetWithText(MxButton, _en.accountSignOut),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  accountTest('signing out from screen 32 pushed over Settings leaves it '
      '(device check D6, F1)', (tester, env, world) async {
    await linkEmail(world);
    world.device.pending = 0;
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();
    await tester.tap(find.text('a@example.com'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);

    await tester.tap(find.text(_en.accountSignOut));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.widgetWithText(MxButton, _en.accountSignOut),
      ),
    );
    await tester.pumpAndSettle();

    expect(world.state, isA<Ready>());
    expect(find.byType(AccountScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  accountTest('a Google sign-in that moves the phone to its account leaves '
      'the pushed sign-in for screen 32 (device check D6, F2)', (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: world.gateway.google.email);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.accountSignIn));
    await _settle(tester);
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.tap(find.text(_en.accountContinueGoogle));
    await tester.pumpAndSettle();
    // The phone holds no library: no merge sheet, and the Google account
    // just picked signs in to the target at once, with no second sign-in
    // page (owner 2026-10-08).

    expect(world.state, isA<Ready>());
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text(_en.accountOfflineNote), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  accountTest('a slow account check after that Google sign-in still ends on '
      'screen 32, with no error (final review 2026-10-08, I1)', (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: world.gateway.google.email);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.accountSignIn));
    await _settle(tester);

    final held = world.api.holdMe = Completer<void>();
    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);
    await _settle(tester);
    world.api.holdMe = null;
    held.complete();
    await tester.pumpAndSettle();

    expect(world.state, isA<Ready>());
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  accountTest('while the picked Google account signs in, the layer does not '
      'raise the keyboard (final review 2026-10-08, M2)', (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: world.gateway.google.email);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.accountSignIn));
    await _settle(tester);

    final held = world.gateway.holdGoogleSignIn = Completer<void>();
    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);

    final layerField = find.descendant(
      of: find.byType(AccountTransitionLayerWidget),
      matching: find.byType(MxTextField),
    );
    expect(layerField, findsOneWidget);
    expect(tester.widget<MxTextField>(layerField).isAutofocused, isFalse);

    world.gateway.holdGoogleSignIn = null;
    held.complete();
    await tester.pumpAndSettle();
    expect(world.state, isA<Ready>());
  });

  libraryTest('a build that cannot sign in has no Account section and no '
      'Welcome', (tester, env) async {
    await pumpMemoxApp(tester, env);

    expect(find.byType(WelcomeScreen), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(MxBottomNav),
        matching: find.text(_en.navSettings),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_en.accountSignIn), findsNothing);
  });

  accountTest('an admin opens Users from Settings, and Back returns '
      '(users spec U5)', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        isAdminProvider.overrideWithValue(true),
        userRoleRepositoryProvider.overrideWithValue(
          FakeUserRoleRepository([managedUser('ann@example.com')]),
        ),
      ],
    );
    _router(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.settingsAdminTools));
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget);
    await tester.tap(find.text(_en.usersTitle));
    await tester.pumpAndSettle();
    expect(find.byType(UsersScreen), findsOneWidget);
    expect(find.text('ann@example.com'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget, reason: 'Back to 23b');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  accountTest('a non-admin\'s deep link to Admin meets the gate, titled '
      'Admin', (tester, env, world) async {
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));

    _router(tester).go(AppRoutes.settingsAdmin);
    await tester.pumpAndSettle();

    expect(find.byType(AdminScreen), findsNothing);
    expect(find.text(_en.monitoringNotAdminTitle), findsOneWidget);
    expect(find.text(_en.settingsAdmin), findsOneWidget);
  });

  accountTest('an admin\'s deep link to Monitoring returns to the hub, not '
      'to 23b (settings hub spec D5)', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        isAdminProvider.overrideWithValue(true),
      ],
    );

    _router(tester).go(AppRoutes.settingsMonitoring);
    await tester.pumpAndSettle();
    expect(find.text(_en.monitoringTitle), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  accountTest('a non-admin\'s deep link to Users meets the gate, titled '
      'Users', (tester, env, world) async {
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));

    _router(tester).go(AppRoutes.settingsUsers);
    await tester.pumpAndSettle();

    expect(find.byType(UsersScreen), findsNothing);
    expect(find.text(_en.monitoringNotAdminTitle), findsOneWidget);
    expect(find.text(_en.usersTitle), findsOneWidget);
  });
}

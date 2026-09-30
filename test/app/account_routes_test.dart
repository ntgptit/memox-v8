import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/account_screen.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../support/account_harness.dart';
import '../support/fake_auth_server.dart';
import '../support/library_harness.dart';

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
}

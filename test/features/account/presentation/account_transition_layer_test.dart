import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/providers/unsent_count_provider.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/code_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// The app on Settings › Theme, a page a stray Back would pop.
Future<void> _onThemePage(
  WidgetTester tester,
  LibraryEnv env,
  AuthWorld world,
) async {
  await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
  await tester.tap(
    find.descendant(
      of: find.byType(MxBottomNav),
      matching: find.text(_en.navSettings),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.settingsTheme));
  await _settle(tester);
  expect(find.byType(ThemeScreen), findsOneWidget);
}

/// A system back swipe, as Android 14 sends it with predictive back on.
Future<void> _backSwipe(WidgetTester tester) async {
  const codec = StandardMethodCodec();
  Future<void> send(String method, [Object? arguments]) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.backGesture.name,
        codec.encodeMethodCall(MethodCall(method, arguments)),
        (_) {},
      );
  const event = {
    'touchOffset': [5.0, 300.0],
    'progress': 0.0,
    'swipeEdge': 0,
  };
  await send('startBackGesture', event);
  await send('updateBackGestureProgress', {...event, 'progress': 0.6});
  await send('commitBackGesture');
  await _settle(tester);
}

void main() {
  accountTest('a switch covers the app, keeps Back inside, and Cancel puts '
      'the page back (Review Focus 2)', (tester, env, world) async {
    await _onThemePage(tester, env, world);

    await world.coordinator.beginSwitch(
      choice: TransitionChoice.discard,
      targetHint: 'b@example.com',
    );
    await _settle(tester);
    expect(find.byType(SignInFormWidget), findsOneWidget);
    expect(find.text(_en.accountTargetLine), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(SignInFormWidget), findsOneWidget);

    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);
    expect(find.byType(CodeFormWidget), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(CodeFormWidget), findsNothing);
    expect(find.byType(SignInFormWidget), findsOneWidget);

    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);
    expect(find.byType(AccountTransitionLayerWidget), findsNothing);
    expect(find.byType(ThemeScreen), findsOneWidget);
    expect(world.state, isA<Ready>());
  });

  accountTest('a system back swipe under the layer never pops the page '
      'beneath, and Back works again once the layer closes', (
    tester,
    env,
    world,
  ) async {
    await _onThemePage(tester, env, world);
    await world.coordinator.beginSwitch(
      choice: TransitionChoice.discard,
      targetHint: 'b@example.com',
    );
    await _settle(tester);

    await _backSwipe(tester);
    expect(find.byType(SignInFormWidget), findsOneWidget);
    expect(find.byType(ThemeScreen, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);
    expect(find.byType(AccountTransitionLayerWidget), findsNothing);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(ThemeScreen), findsNothing);
  });

  accountTest('while the layer shows, the framework takes Back, even over a '
      'root page (Android predictive back)', (tester, env, world) async {
    final handlesBack = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handlesBack.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    // The app is in front, so it tells the platform who handles Back.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    expect(handlesBack.last, isFalse, reason: 'the Library root');

    await world.coordinator.beginSwitch(
      choice: TransitionChoice.discard,
      targetHint: 'b@example.com',
    );
    await _settle(tester);

    expect(handlesBack.last, isTrue);
  });

  accountTest('the layer signs in the target, and the switch finishes '
      'behind it', (tester, env, world) async {
    world.server.addUser(email: 'b@example.com');
    await _onThemePage(tester, env, world);
    await world.coordinator.beginSwitch(
      choice: TransitionChoice.discard,
      targetHint: 'b@example.com',
    );
    await _settle(tester);

    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(CodeFormWidget),
        matching: find.byType(TextField),
      ),
      FakeAuthGateway.code,
    );
    await _settle(tester);
    await _settle(tester);

    expect(find.byType(AccountTransitionLayerWidget), findsNothing);
    expect(
      world.state,
      isA<Ready>().having((s) => s.user.email, 'email', 'b@example.com'),
    );
  });

  accountTest('no connection says the data is safe, and Retry carries on', (
    tester,
    env,
    world,
  ) async {
    await _onThemePage(tester, env, world);
    world.network.goOffline();
    await world.coordinator.beginSwitch(
      choice: TransitionChoice.discard,
      targetHint: 'b@example.com',
    );
    await _settle(tester);

    expect(find.text(_en.accountLayerOffline), findsOneWidget);
    expect(find.text(_en.commonCancel), findsOneWidget);

    world.network.goOnline();
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(find.byType(SignInFormWidget), findsOneWidget);
  });

  accountTest('a refused merge is said once the device is back', (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: 'b@example.com');
    await _onThemePage(tester, env, world);
    await world.coordinator.beginSwitch(
      choice: TransitionChoice.merge,
      targetHint: 'b@example.com',
    );
    await _settle(tester);
    world.server.claims.clear();

    await world.coordinator.requestCode('b@example.com');
    await world.coordinator.verifyCode('b@example.com', FakeAuthGateway.code);
    await _settle(tester);

    expect(find.byType(AccountTransitionLayerWidget), findsNothing);
    expect(find.text(_en.accountMergeNotDone), findsOneWidget);
  });

  accountTest('a refused last-admin deletion is a dialog, not a toast '
      '(P3b B7)', (tester, env, world) async {
    await linkEmail(world);
    world.server.users[world.gateway.currentUserId]!.role = AccountRole.admin;
    await _onThemePage(tester, env, world);

    await world.coordinator.deleteAccount();
    await _settle(tester);

    expect(find.text(_en.accountLastAdminTitle), findsOneWidget);
    expect(find.text(_en.accountLastAdmin), findsOneWidget);
  });

  libraryTest('a sign-out stopped offline offers to go on and lose the '
      'changes', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Transitioning(
            transitionOf(TransitionKind.signOut, TransitionStage.started),
            error: const OfflineFailure(cause: 'test'),
          ),
        ),
        unsentCountProvider.overrideWith((ref) async => 2),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountLayerOffline), findsOneWidget);
    expect(find.text(_en.accountSignOutLosing(2)), findsOneWidget);
    expect(find.text(_en.commonCancel), findsNothing);
  });

  libraryTest('stuck says the data is safe and offers only Retry', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Recovering(
            transitionOf(
              TransitionKind.switchAccount,
              TransitionStage.merged,
              choice: TransitionChoice.merge,
            ),
            isStuck: true,
          ),
        ),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountLayerStuck), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.text(_en.commonCancel), findsNothing);
  });

  libraryTest('running, it names the step and says closing loses nothing', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Transitioning(
            transitionOf(
              TransitionKind.switchAccount,
              TransitionStage.targetSignedIn,
              choice: TransitionChoice.merge,
            ),
          ),
        ),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountStepMerging), findsWidgets);
    expect(find.text(_en.accountSafeToClose), findsOneWidget);
  });
}

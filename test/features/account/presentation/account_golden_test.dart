@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/providers/unsent_count_provider.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_settings_section_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/account_harness.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The Task 6 host: a button that starts the switch for b@example.com.
final Widget _mergeHost = Scaffold(
  body: Consumer(
    builder: (context, ref, _) => Center(
      child: TextButton(
        onPressed: () => startLinkSwitch(context, ref, email: 'b@example.com'),
        child: const Text('go'),
      ),
    ),
  ),
);

/// The layer on [state], over nothing else.
Widget _layer() => AccountTransitionLayerWidget(navigatorKey: GlobalKey());

final _mergeSwitch = TransitionChoice.merge;

AccountTransition _switchAt(TransitionStage stage, {String? hint}) =>
    transitionOf(
      TransitionKind.switchAccount,
      stage,
      choice: _mergeSwitch,
      targetHint: hint,
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// A tap's ink and the pressed overlay fade before the capture.
Future<void> _rest(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 1));

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> capture(
      WidgetTester tester,
      LibraryEnv env,
      Widget screen,
      String name, {
      List<Override> overrides = const [],
      bool hasMark = false,
      Future<void> Function()? before,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          screen,
          brightness,
          overrides: overrides,
        );
        if (hasMark) await precacheGoogleMark(tester);
        await before?.call();
        await expectBoundaryGolden(tester, 'goldens/${name}_$theme.png');
      });
    }

    accountTest('welcome, ready, $theme', (tester, env, world) async {
      await capture(
        tester,
        env,
        WelcomeScreen(onDone: () {}, onEmail: () {}),
        'welcome_ready',
        overrides: accountOverrides(world),
        hasMark: true,
      );
    });

    accountTest('welcome, offline, $theme', (tester, env, world) async {
      await capture(
        tester,
        env,
        WelcomeScreen(onDone: () {}, onEmail: () {}),
        'welcome_offline',
        overrides: [...accountOverrides(world), authStateOf(const LocalOnly())],
        hasMark: true,
      );
    });

    accountTest('sign-in, link, $theme', (tester, env, world) async {
      await capture(
        tester,
        env,
        SignInScreen(onCodeSent: (_) {}, onSignedIn: () {}),
        'sign_in_link',
        overrides: accountOverrides(world),
        hasMark: true,
      );
    });

    accountTest('sign-in, invalid address, $theme', (tester, env, world) async {
      await capture(
        tester,
        env,
        SignInScreen(onCodeSent: (_) {}, onSignedIn: () {}),
        'sign_in_invalid',
        overrides: accountOverrides(world),
        hasMark: true,
        before: () async {
          await tester.enterText(find.byType(TextField), 'a@');
          await tester.tap(find.text(_en.accountSendCode));
          await _settle(tester);
          await _rest(tester);
        },
      );
    });

    accountTest('code, waiting, $theme', (tester, env, world) async {
      await world.coordinator.requestCode('a@example.com');
      await capture(
        tester,
        env,
        CodeScreen(email: 'a@example.com', onSignedIn: () {}),
        'code_waiting',
        overrides: accountOverrides(world),
      );
    });

    accountTest('code, wrong, $theme', (tester, env, world) async {
      await world.coordinator.requestCode('a@example.com');
      await capture(
        tester,
        env,
        CodeScreen(email: 'a@example.com', onSignedIn: () {}),
        'code_wrong',
        overrides: accountOverrides(world),
        before: () async {
          await tester.enterText(find.byType(TextField), '000000');
          await _settle(tester);
        },
      );
    });

    accountTest('code, offline with the digits kept, $theme', (
      tester,
      env,
      world,
    ) async {
      await world.coordinator.requestCode('a@example.com');
      await capture(
        tester,
        env,
        CodeScreen(email: 'a@example.com', onSignedIn: () {}),
        'code_offline_kept',
        overrides: accountOverrides(world),
        before: () async {
          world.network.goOffline();
          await tester.enterText(find.byType(TextField), '123456');
          await _settle(tester);
          expect(find.text(_en.accountOffline), findsOneWidget);
          expect(find.text(_en.commonRetry), findsOneWidget);
        },
      );
    });

    for (final (name, isDiscarding) in [
      ('merge_sheet_merge', false),
      ('merge_sheet_discard', true),
    ]) {
      accountTest('$name, $theme', (tester, env, world) async {
        final korean = await env.decks.root('Korean');
        await insertCard(env.db, id: 'c1', deckId: korean.id);
        await insertCard(env.db, id: 'c2', deckId: korean.id);
        await capture(
          tester,
          env,
          _mergeHost,
          name,
          overrides: accountOverrides(world),
          before: () async {
            await tester.tap(find.text('go'));
            await _settle(tester);
            await _rest(tester);
            if (!isDiscarding) return;
            await tester.tap(find.text(_en.accountDiscard));
            await _settle(tester);
            await _rest(tester);
          },
        );
      });
    }

    final layers = <(String, AuthState, List<Override>)>[
      ('layer_sending', Transitioning(_switchAt(TransitionStage.started)), []),
      (
        'layer_merging',
        Transitioning(_switchAt(TransitionStage.targetSignedIn)),
        [],
      ),
      (
        'layer_offline',
        Transitioning(
          _switchAt(TransitionStage.started),
          error: const OfflineFailure(cause: 'golden'),
        ),
        [],
      ),
      (
        'layer_target',
        Transitioning(
          _switchAt(TransitionStage.claimed, hint: 'b@example.com'),
          isAwaitingTargetSignIn: true,
        ),
        [],
      ),
      (
        'layer_sign_out_offline',
        Transitioning(
          transitionOf(TransitionKind.signOut, TransitionStage.started),
          error: const OfflineFailure(cause: 'golden'),
        ),
        [unsentCountProvider.overrideWith((ref) async => 2)],
      ),
      (
        'layer_stuck',
        Recovering(_switchAt(TransitionStage.merged), isStuck: true),
        [],
      ),
    ];
    for (final (name, state, extra) in layers) {
      libraryTest('$name, $theme', (tester, env) async {
        await capture(
          tester,
          env,
          _layer(),
          name,
          overrides: [authStateOf(state), ...extra],
          hasMark: name == 'layer_target',
          before: name == 'layer_stuck'
              ? () async {
                  expect(find.text(_en.accountCloseApp), findsOneWidget);
                }
              : null,
        );
      });
    }

    accountTest('settings with the Account section, $theme', (
      tester,
      env,
      world,
    ) async {
      await capture(
        tester,
        env,
        SettingsScreen(
          onOpenTheme: () {},
          onOpenLanguage: () {},
          onOpenReminder: () {},
          onAppOptionsReset: () {},
          onOpenSync: () {},
          accountSection: AccountSettingsSectionWidget(
            onSignIn: () {},
            onOpenAccount: () {},
            onSignInAgain: () {},
          ),
        ),
        'settings_account',
        overrides: accountOverrides(world),
      );
    });
  }
}

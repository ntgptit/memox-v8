@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/account_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_reauth_notice_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_settings_section_widget.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/account_harness.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// P3b (account UI spec §9, §9.1): screen 32, its dialogs, and the re-auth
// surfaces on 23, 13 and 30.

final _en = lookupAppLocalizations(const Locale('en'));

const _account = AccountUser(
  id: 'x',
  email: 'a@example.com',
  isAnonymous: false,
  role: AccountRole.user,
);

final Override _refused = authStateOf(const ReauthRequired(_account));

Widget _account32() => AccountScreen(onSignInAgain: () {});

Widget _settings() => SettingsScreen(
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
);

Widget _reauth30() => SignInScreen(
  purpose: SignInPurpose.reauth,
  onCodeSent: (_) {},
  onSignedIn: () {},
  onLeftAccount: () {},
);

/// A button that opens the last-admin dialog.
final Widget _lastAdminHost = Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => unawaited(showLastAdminDialog(context)),
        child: const Text('go'),
      ),
    ),
  ),
);

/// A root deck with cards due today, so 13 has a page under its notice.
Future<void> _studyDeck(LibraryEnv env) async {
  final root = await env.decks.root('IELTS Academic Word List');
  final leaf = await env.decks.sub(root.id, 'Words');
  for (var i = 0; i < 4; i++) {
    await insertCard(
      env.db,
      id: 'c$i',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 24, 8),
      box: 2,
    );
  }
  await lockScheduler(env.db, root.id);
}

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

    Future<void> Function() tapping(WidgetTester tester, String label) =>
        () async {
          await tester.tap(find.text(label));
          await _settle(tester);
          await _rest(tester);
        };

    accountTest('account, ready, $theme', (tester, env, world) async {
      await linkEmail(world);
      await capture(
        tester,
        env,
        _account32(),
        'account_ready',
        overrides: accountOverrides(world),
      );
    });

    accountTest('account, validating, $theme', (tester, env, world) async {
      await capture(
        tester,
        env,
        _account32(),
        'account_validating',
        overrides: [
          ...accountOverrides(world),
          authStateOf(const Validating(_account)),
        ],
      );
    });

    accountTest('account, reauth, $theme', (tester, env, world) async {
      await capture(
        tester,
        env,
        _account32(),
        'account_reauth',
        overrides: [...accountOverrides(world), _refused],
      );
    });

    for (final (name, label, isOffline) in [
      ('account_switch_confirm', _en.accountSwitch, false),
      ('account_sign_out_confirm', _en.accountSignOut, false),
      ('account_sign_out_loss', _en.accountSignOut, true),
      ('account_delete_confirm', _en.accountDelete, false),
      ('account_delete_offline', _en.accountDelete, true),
    ]) {
      accountTest('$name, $theme', (tester, env, world) async {
        await linkEmail(world);
        if (isOffline) world.network.goOffline();
        await capture(
          tester,
          env,
          _account32(),
          name,
          overrides: accountOverrides(world),
          before: tapping(tester, label),
        );
      });
    }

    accountTest('account, last admin, $theme', (tester, env, world) async {
      await capture(
        tester,
        env,
        _lastAdminHost,
        'account_last_admin',
        overrides: accountOverrides(world),
        before: tapping(tester, 'go'),
      );
    });

    accountTest('settings, signed in, $theme', (tester, env, world) async {
      await linkEmail(world);
      await capture(
        tester,
        env,
        _settings(),
        'settings_account_signed_in',
        overrides: accountOverrides(world),
      );
    });

    accountTest('settings, reauth, $theme', (tester, env, world) async {
      await capture(
        tester,
        env,
        _settings(),
        'settings_account_reauth',
        overrides: [...accountOverrides(world), _refused],
      );
    });

    accountTest('study home, reauth, $theme', (tester, env, world) async {
      await _studyDeck(env);
      await capture(
        tester,
        env,
        StudyHomeScreen(
          onOpenSession: (_) {},
          onOpenDeck: (_) {},
          onOpenLibrary: () {},
          onOpenStarterDecks: () {},
          onOpenSync: () {},
          reauthNotice: AccountReauthNoticeWidget(onSignIn: () {}),
        ),
        'study_home_reauth',
        overrides: [...accountOverrides(world), _refused],
      );
    });

    accountTest('sign-in, reauth, $theme', (tester, env, world) async {
      await refuseSession(world);
      await capture(
        tester,
        env,
        _reauth30(),
        'sign_in_reauth',
        overrides: accountOverrides(world),
        hasMark: true,
        before: () => _settle(tester),
      );
    });

    accountTest('sign-in, unsent loss, $theme', (tester, env, world) async {
      await refuseSession(world);
      await capture(
        tester,
        env,
        _reauth30(),
        'sign_in_unsent_loss',
        overrides: accountOverrides(world),
        hasMark: true,
        before: () async {
          await _settle(tester);
          await tester.enterText(find.byType(TextField), 'b@example.com');
          await tapping(tester, _en.accountSendCode)();
        },
      );
    });

    accountTest('sign-in, continue without, $theme', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await capture(
        tester,
        env,
        _reauth30(),
        'sign_in_continue_without',
        overrides: accountOverrides(world),
        hasMark: true,
        before: () async {
          await _settle(tester);
          await tapping(tester, _en.accountContinueWithout)();
        },
      );
    });
  }
}

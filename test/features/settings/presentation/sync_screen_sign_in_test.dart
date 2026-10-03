import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../shared/expect_one_primary.dart';
import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

// Screen 27: a refused session offers Sign in (SP2b 2.37).

final _en = lookupAppLocalizations(const Locale('en'));

const _account = AccountUser(
  id: 'x',
  email: 'a@example.com',
  isAnonymous: false,
  role: AccountRole.user,
);

SyncStatus _signInFailed(LibraryEnv env, {int rejectedCount = 0}) => SyncStatus(
  rejectedCount: rejectedCount,
  lastFailure: LastSyncFailure(SyncFailureKind.signIn, env.clock.now()),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

MxButton _syncNow(WidgetTester tester) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, _en.syncNow));

void main() {
  libraryTest('a refused session says sync is paused and offers Sign in; Sync '
      'now steps back (2.37)', (tester, env) async {
    var signIns = 0;
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () => signIns++),
      overrides: [
        ...syncOverrides(_signInFailed(env)),
        authStateOf(const ReauthRequired(_account)),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.syncSignInAgain), findsOneWidget);
    expect(find.text(_en.syncFailedSignIn), findsNothing);
    expect(
      tester.widget<MxInlineBanner>(find.byType(MxInlineBanner)).tone,
      MxBannerTone.warning,
    );
    expect(_syncNow(tester).tone, MxButtonTone.outline);
    expectOnePrimaryPerDecision(tester);

    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    expect(signIns, 1);
  });

  libraryTest('a sign-in failure with no refused session is the plain '
      'sentence: nothing to sign in to (2.37)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () {}),
      overrides: [
        ...syncOverrides(_signInFailed(env)),
        authStateOf(const Ready(_account)),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.syncFailedSignIn), findsOneWidget);
    expect(find.text(_en.syncSignInAgain), findsNothing);
    expect(find.widgetWithText(MxButton, _en.accountSignIn), findsNothing);
    expect(_syncNow(tester).tone, MxButtonTone.primary);
  });

  libraryTest('refused rows keep their own banner over a refused session '
      '(2.37)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () {}),
      overrides: [
        ...syncOverrides(_signInFailed(env, rejectedCount: 2)),
        authStateOf(const ReauthRequired(_account)),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.syncRejectedTitle(2)), findsOneWidget);
    expect(find.text(_en.syncSignInAgain), findsNothing);
  });
}

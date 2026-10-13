import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

// Screen 30's Google when that Google account already has an account: it
// signs in to it at once, with no second sign-in page (owner 2026-10-08,
// after the device check of build 18).

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  SignInScreen screen() => SignInScreen(onCodeSent: (_) {}, onSignedIn: () {});

  accountTest("Google whose account is another account's signs in to it at "
      'once on an empty phone (owner 2026-10-08)', (tester, env, world) async {
    world.server.addUser(email: 'g@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);
    await tester.pumpAndSettle();

    expect(
      world.state,
      isA<Ready>()
          .having((s) => s.user.email, 'email', 'g@example.com')
          .having((s) => s.user.isAnonymous, 'anonymous', isFalse),
    );
  });

  accountTest('when that sign-in fails, the switch waits for the target '
      'sign-in and says why (owner 2026-10-08)', (tester, env, world) async {
    world.server.addUser(email: 'g@example.com');
    world.gateway.failNextGoogleSignIn = const OfflineFailure(cause: 'test');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);
    await tester.pumpAndSettle();

    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.isAwaitingTargetSignIn,
        'awaiting target',
        isTrue,
      ),
    );
    expect(
      find.text(signInProblemText(_en, SignInProblem.offline)),
      findsOneWidget,
    );
  });
}

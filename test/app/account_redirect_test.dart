import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/account_redirect.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';

import '../support/account_harness.dart';

const _anon = Ready(
  AccountUser(id: 'n', isAnonymous: true, role: AccountRole.user),
);
const _signedIn = Ready(
  AccountUser(
    id: 'x',
    email: 'a@example.com',
    isAnonymous: false,
    role: AccountRole.user,
  ),
);

void main() {
  String? redirect(
    String location, {
    bool isWelcomeDue = false,
    AuthState? account = _anon,
  }) => accountRedirect(
    Uri.parse(location),
    isWelcomeDue: isWelcomeDue,
    account: account,
  );

  test('Welcome takes any location while it is due, and keeps it', () {
    expect(redirect('/decks', isWelcomeDue: true), '/welcome?from=%2Fdecks');
    expect(
      redirect('/progress', isWelcomeDue: true),
      '/welcome?from=%2Fprogress',
    );
    expect(redirect('/welcome?from=%2Fdecks', isWelcomeDue: true), isNull);
  });

  test('nothing redirects once Welcome is answered', () {
    expect(redirect('/decks'), isNull);
    expect(redirect(AppRoutes.settingsSignInLink), isNull);
  });

  test('the attach flow closes once the device holds an account', () {
    expect(
      redirect(AppRoutes.settingsSignInLink, account: _signedIn),
      AppRoutes.settingsAccount,
    );
    expect(
      redirect(
        AppRoutes.settingsSignInCodeLink('a@example.com'),
        account: _signedIn,
      ),
      AppRoutes.settingsAccount,
    );
    expect(
      redirect('${AppRoutes.settingsSignIn}?mode=reauth', account: _signedIn),
      isNull,
      reason: 'P3b re-auth signs in an account',
    );
  });

  test('screen 32 needs an account; a transition keeps it '
      '(Review Focus 3)', () {
    expect(
      redirect(AppRoutes.settingsAccount, account: _anon),
      AppRoutes.settings,
    );
    expect(
      redirect(AppRoutes.settingsAccount, account: const LocalOnly()),
      AppRoutes.settings,
    );
    expect(redirect(AppRoutes.settingsAccount, account: _signedIn), isNull);
    expect(
      redirect(
        AppRoutes.settingsAccount,
        account: Transitioning(
          transitionOf(TransitionKind.delete, TransitionStage.started),
        ),
      ),
      isNull,
    );
    expect(
      redirect(AppRoutes.settingsAccount, account: const Booting()),
      isNull,
    );
  });

  test('the paths are what the routes register', () {
    expect(AppRoutes.settingsSignInLink, '/settings/sign-in?mode=link');
    expect(
      AppRoutes.settingsSignInCodeLink('a@example.com'),
      '/settings/sign-in/code?mode=link&email=a%40example.com',
    );
    expect(AppRoutes.welcomeFrom('/decks'), '/welcome?from=%2Fdecks');
    expect(AppRoutes.settingsAccount, '/settings/account');
    expect(AppRoutes.settingsUsers, '/settings/users');
    expect(
      AppRoutes.settingsSignInReauth(from: '/study'),
      '/settings/sign-in?mode=reauth&from=%2Fstudy',
    );
    expect(
      AppRoutes.settingsSignInCodeReauth('a@example.com', from: '/settings'),
      '/settings/sign-in/code?mode=reauth&email=a%40example.com'
      '&from=%2Fsettings',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/account_redirect.dart';
import 'package:memox/app/router/app_routes.dart';

void main() {
  String? redirect(
    String location, {
    bool isWelcomeDue = false,
    bool hasAccount = false,
  }) => accountRedirect(
    Uri.parse(location),
    isWelcomeDue: isWelcomeDue,
    hasAccount: hasAccount,
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
      redirect(AppRoutes.settingsSignInLink, hasAccount: true),
      AppRoutes.settings,
    );
    expect(
      redirect(
        AppRoutes.settingsSignInCodeLink('a@example.com'),
        hasAccount: true,
      ),
      AppRoutes.settings,
    );
    expect(
      redirect('${AppRoutes.settingsSignIn}?mode=reauth', hasAccount: true),
      isNull,
      reason: 'P3b re-auth signs in an account',
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

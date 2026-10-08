import 'package:flutter/foundation.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';

/// The router's account rules (account UI spec §4, §9 B9). Signing in
/// stays optional, so nothing else redirects:
/// - Welcome until it is answered, keeping the location asked for;
/// - no attach flow once the device holds an account: screen 32 instead;
/// - no screen 32 on a plainly anonymous device (plan ruling 4). During a
///   start or a transition nothing moves.
String? accountRedirect(
  Uri location, {
  required bool isWelcomeDue,
  required AuthState? account,
}) {
  if (isWelcomeDue && location.path != AppRoutes.welcome) {
    return AppRoutes.welcomeFrom(location.toString());
  }
  final mode =
      location.queryParameters[AppRoutes.accountModeParam] ??
      AppRoutes.accountLinkMode;
  final isAttach =
      location.path.startsWith(AppRoutes.settingsSignIn) &&
      mode == AppRoutes.accountLinkMode;
  if (isAttach && deviceAccountOf(account) != null) {
    // A link begun on Welcome ends where it was headed (login navigation
    // review 2026-10-08); from Settings it ends on screen 32.
    final from = location.queryParameters[AppRoutes.accountFromParam];
    return from == null
        ? AppRoutes.settingsAccount
        : AppRoutes.inAppOr(from, AppRoutes.settingsAccount);
  }
  if (location.path == AppRoutes.settingsAccount && _isAnonymous(account)) {
    return AppRoutes.settings;
  }
  return null;
}

bool _isAnonymous(AuthState? account) => switch (account) {
  Ready(:final user) => user.isAnonymous,
  Validating(:final last) => last == null || last.isAnonymous,
  LocalOnly() || Bootstrapping() => true,
  _ => false,
};

/// Tells the router to run [accountRedirect] again: the welcome flag or
/// the account changed.
final class AccountRouteRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

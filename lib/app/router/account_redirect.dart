import 'package:flutter/foundation.dart';
import 'package:memox/app/router/app_routes.dart';

/// The router's two account rules (account UI spec §4). Signing in stays
/// optional, so nothing else redirects:
/// - Welcome until it is answered, keeping the location asked for;
/// - no attach flow once the device holds an account (P3a plan ruling 2).
String? accountRedirect(
  Uri location, {
  required bool isWelcomeDue,
  required bool hasAccount,
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
  if (hasAccount && isAttach) return AppRoutes.settings;
  return null;
}

/// Tells the router to run [accountRedirect] again: the welcome flag or
/// the account changed.
final class AccountRouteRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/presentation/screens/account_screen.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_reauth_notice_widget.dart';
import 'package:memox/features/account/presentation/widgets/items/account_settings_row_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_settings_banner_widget.dart';

/// Screen 29 (account UI spec §5.1): the first launch, over everything.
/// Its exits go on to where the launch was headed; email opens screen 30
/// with Settings under it (P3a plan ruling 4).
GoRoute welcomeRoute() => GoRoute(
  path: AppRoutes.welcome,
  builder: (context, state) {
    final from = AppRoutes.inAppOr(
      state.uri.queryParameters[AppRoutes.welcomeFromParam],
      AppRoutes.decks,
    );
    return WelcomeScreen(
      onDone: () => context.go(from),
      onEmail: () => context.go(AppRoutes.settingsSignInLink),
    );
  },
);

/// Screens 30 and 31 (spec §5.2) under Settings, on the root navigator
/// like Sync (plan ruling 1). The link ends on screen 32, a re-auth where it
/// began (P3b B9).
GoRoute signInRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsSignInChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) {
    final flow = _SignInFlow.of(state.uri);
    return SignInScreen(
      purpose: flow.purpose,
      onCodeSent: (email) => unawaited(context.push(flow.codeLocation(email))),
      onSignedIn: () => context.go(flow.end),
      onLeftAccount: () => context.go(flow.end),
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.settingsSignInCodeChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) {
        final flow = _SignInFlow.of(state.uri);
        return CodeScreen(
          email: state.uri.queryParameters[AppRoutes.accountEmailParam] ?? '',
          purpose: flow.purpose,
          onSignedIn: () => context.go(flow.end),
        );
      },
    ),
  ],
);

/// Screen 32 (spec §5.6) under Settings, on the root navigator.
GoRoute accountRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsAccountChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) => AccountScreen(
    onSignInAgain: () => unawaited(
      context.push(
        AppRoutes.settingsSignInReauth(from: AppRoutes.settingsAccount),
      ),
    ),
  ),
);

/// Study home's notice for an expired sign-in (spec §5.7). Screen 30 opens
/// under Settings, as the sync notice's Details does (plan ruling 3).
Widget accountReauthNotice(BuildContext context) => AccountReauthNoticeWidget(
  onSignIn: () =>
      context.go(AppRoutes.settingsSignInReauth(from: AppRoutes.study)),
);

/// Where a sign-in flow began and ends (spec §9 B9): the link ends on
/// screen 32; a re-auth returns to where it was opened.
final class _SignInFlow {
  const _SignInFlow(this.purpose, this.from);

  factory _SignInFlow.of(Uri uri) {
    final query = uri.queryParameters;
    final isReauth =
        query[AppRoutes.accountModeParam] == AppRoutes.accountReauthMode;
    return _SignInFlow(
      isReauth ? SignInPurpose.reauth : SignInPurpose.link,
      AppRoutes.inAppOr(query[AppRoutes.accountFromParam], AppRoutes.settings),
    );
  }

  final SignInPurpose purpose;
  final String from;

  String get end =>
      purpose == SignInPurpose.reauth ? from : AppRoutes.settingsAccount;

  String codeLocation(String email) => purpose == SignInPurpose.reauth
      ? AppRoutes.settingsSignInCodeReauth(email, from: from)
      : AppRoutes.settingsSignInCodeLink(email);
}

/// Whether this build can have an account at all: the hub draws its
/// "Account & sync" section only when it gets a row, so a build without
/// Supabase (no coordinator) gets none and shows no empty section
/// (settings hub spec §5.1).
bool _hasAccount(BuildContext context) =>
    ProviderScope.containerOf(context).read(accountCoordinatorProvider) != null;

/// The hub's account row (settings hub spec D7); null when the build has no
/// account.
Widget? accountSettingsRow(BuildContext context) => _hasAccount(context)
    ? AccountSettingsRowWidget(
        onSignIn: () => unawaited(context.push(AppRoutes.settingsSignInLink)),
        onOpenAccount: () => unawaited(context.push(AppRoutes.settingsAccount)),
      )
    : null;

/// The expired sign-in banner above the hub's Account & sync section; null
/// when the build has no account.
Widget? accountSettingsBanner(BuildContext context) => _hasAccount(context)
    ? AccountSettingsBannerWidget(
        onSignIn: () => unawaited(
          context.push(
            AppRoutes.settingsSignInReauth(from: AppRoutes.settings),
          ),
        ),
      )
    : null;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_settings_section_widget.dart';

/// Screen 29 (account UI spec §5.1): the first launch, over everything.
/// Its exits go on to where the launch was headed; email opens screen 30
/// with Settings under it (P3a plan ruling 4).
GoRoute welcomeRoute() => GoRoute(
  path: AppRoutes.welcome,
  builder: (context, state) {
    final from =
        state.uri.queryParameters[AppRoutes.welcomeFromParam] ??
        AppRoutes.decks;
    return WelcomeScreen(
      onDone: () => context.go(from),
      onEmail: () => context.go(AppRoutes.settingsSignInLink),
    );
  },
);

/// Screens 30 and 31 (spec §5.2) under Settings, on the root navigator
/// like Sync (plan ruling 1). The flow ends on Settings (plan ruling 2).
GoRoute signInRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsSignInChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) => SignInScreen(
    onCodeSent: (email) =>
        unawaited(context.push(AppRoutes.settingsSignInCodeLink(email))),
    onSignedIn: () => context.go(AppRoutes.settings),
  ),
  routes: [
    GoRoute(
      path: AppRoutes.settingsSignInCodeChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) => CodeScreen(
        email: state.uri.queryParameters[AppRoutes.accountEmailParam] ?? '',
        onSignedIn: () => context.go(AppRoutes.settings),
      ),
    ),
  ],
);

/// Screen 23's Account section (spec §5.5).
Widget accountSettingsSection(BuildContext context) =>
    AccountSettingsSectionWidget(
      onSignIn: () => unawaited(context.push(AppRoutes.settingsSignInLink)),
    );

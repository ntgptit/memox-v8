import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../support/account_harness.dart';
import '../support/fake_auth_server.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

/// Screen 27's route (SP2b 2.37): Sign in opens screen 30 in re-auth mode and
/// a successful sign-in returns to Sync.
void main() {
  accountTest('Sync offers Sign in on a refused session, and signing in '
      'returns to Sync', (tester, env, world) async {
    await refuseSession(world);
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        syncStatusProvider.overrideWith(
          (ref) => Stream.value(
            SyncStatus(
              lastFailure: LastSyncFailure(
                SyncFailureKind.signIn,
                env.clock.now(),
              ),
            ),
          ),
        ),
      ],
    );
    _router(tester).go(AppRoutes.settingsSync);
    await tester.pumpAndSettle();
    expect(find.text(_en.syncSignInAgain), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    await tester.tap(find.text(_en.accountSendCode)); // the address is filled
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pumpAndSettle();

    expect(
      _router(tester).routeInformationProvider.value.uri.path,
      AppRoutes.settingsSync,
    );
    expect(world.state, isA<Ready>());
  });
}

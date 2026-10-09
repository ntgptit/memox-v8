import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/account_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _account = AccountUser(
  id: 'x',
  email: 'a@example.com',
  isAnonymous: false,
  role: AccountRole.user,
);

MxSettingsRow _row(WidgetTester tester, String label) =>
    tester.widget<MxSettingsRow>(find.widgetWithText(MxSettingsRow, label));

void main() {
  late int signIns;

  setUp(() => signIns = 0);

  Widget screen() => AccountScreen(onSignInAgain: () => signIns++);

  accountTest('the account, how it signs in, and three commands', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text(_en.accountMethodEmail), findsOneWidget);
    for (final label in [
      _en.accountSwitch,
      _en.accountSignOut,
      _en.accountDelete,
    ]) {
      expect(_row(tester, label).isEnabled, isTrue);
      // Each opens a dialog: no chevron (critique 2026-10-02).
      expect(_row(tester, label).isAction, isTrue);
    }
    expect(
      _en.accountSignOutHint,
      "Removes this phone's data · sign in again to get it back",
    );
    expect(find.text(_en.accountSignOutHint), findsOneWidget);
  });

  accountTest('checked again offline: the commands wait and say why '
      '(Review Focus 5)', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        authStateOf(const Validating(_account)),
      ],
    );

    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text(_en.accountNeedsConnection), findsOneWidget);
    expect(_row(tester, _en.accountSignOut).isEnabled, isFalse);
  });

  accountTest('an expired sign-in shows the banner, whose Sign in opens 30', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        authStateOf(const ReauthRequired(_account)),
      ],
    );

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(_row(tester, _en.accountDelete).isEnabled, isFalse);
    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    expect(signIns, 1);
  });

  accountTest('Switch account asks, then starts the switch', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountSwitch));
    await tester.pumpAndSettle();
    expect(find.text(_en.accountSwitchTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(MxButton, _en.accountSwitchConfirm));
    await tester.pumpAndSettle();

    expect(world.state, isA<Transitioning>());
  });

  accountTest('Sign out offline with unsent changes names the loss', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    world.network.goOffline();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountSignOut));
    await tester.pumpAndSettle();

    expect(find.text(_en.accountSignOutLossTitle), findsOneWidget);
    expect(find.text(_en.accountSignOutLossBody(2)), findsOneWidget);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).isDestructive,
      isTrue,
    );
  });

  accountTest('Sign out online confirms in warning: nothing is lost, but '
      'the phone is cleared (critique 2026-10-02, F3)', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountSignOut));
    await tester.pumpAndSettle();

    expect(find.text(_en.accountSignOutTitle), findsOneWidget);
    final actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect((actions.isWarning, actions.isDestructive), (true, false));
  });

  accountTest('a second tap while a command asks opens no second dialog '
      '(P3b minor M3)', (tester, env, world) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    _row(tester, _en.accountSignOut).onTap!();
    _row(tester, _en.accountSignOut).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MxDialog), findsOneWidget);

    await tester.tap(find.text(_en.commonCancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    _row(tester, _en.accountSignOut).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MxDialog), findsOneWidget);
  });

  accountTest('Delete offline cannot be confirmed', (tester, env, world) async {
    await linkEmail(world);
    world.network.goOffline();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountDelete));
    await tester.pumpAndSettle();

    expect(find.text(_en.accountDeleteOffline), findsOneWidget);
    final confirm = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.accountDeleteConfirm),
    );
    expect(confirm.onPressed, isNull);
  });

  accountTest('Delete confirms with the short verb (owner 2026-10-06)', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountDelete));
    await tester.pumpAndSettle();

    // The title names the account, so the confirm is the verb alone.
    expect(
      find.widgetWithText(MxButton, _en.accountDeleteConfirm),
      findsOneWidget,
    );
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/presentation/screens/users_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/users_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _me = AccountUser(
  id: 'me',
  email: 'me@example.com',
  isAnonymous: false,
  role: AccountRole.admin,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late FakeUserRoleRepository roles;

  setUp(() {
    roles = FakeUserRoleRepository([
      managedUser('ann@example.com', role: AccountRole.admin),
      managedUser('bob@example.com'),
      managedUser('me@example.com', role: AccountRole.admin),
    ]);
  });

  List<Override> overrides() => [
    userRoleRepositoryProvider.overrideWithValue(roles),
    currentAccountProvider.overrideWithValue(_me),
  ];

  Future<void> pump(WidgetTester tester, LibraryEnv env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const UsersScreen(),
      overrides: overrides(),
    );
    await _settle(tester);
  }

  MxButton save(WidgetTester tester) =>
      tester.widget<MxButton>(find.widgetWithText(MxButton, _en.usersSave));

  libraryTest('the accounts, their join date and role, and the end', (
    tester,
    env,
  ) async {
    await pump(tester, env);

    expect(find.text(_en.usersSection.toUpperCase()), findsOneWidget);
    expect(find.text('ann@example.com'), findsOneWidget);
    expect(find.text(_en.usersJoined('Sep 1, 2026')), findsNWidgets(2));
    expect(find.text(_en.usersRoleAdmin), findsNWidgets(2));
    expect(find.text(_en.usersRoleUser), findsOneWidget);
    expect(find.text(_en.usersNoMore), findsOneWidget);
  });

  libraryTest('the admin\'s own row says You and opens nothing '
      '(Review Focus 2)', (tester, env) async {
    await pump(tester, env);

    expect(find.text(_en.usersJoinedYou('Sep 1, 2026')), findsOneWidget);
    await tester.tap(find.text('me@example.com'));
    await _settle(tester);
    expect(find.byType(MxBottomSheet), findsNothing);
  });

  libraryTest('the sheet saves only a different role (Review Focus 3), and '
      'the row changes', (tester, env) async {
    await pump(tester, env);

    await tester.tap(find.text('bob@example.com'));
    await _settle(tester);
    expect(find.byType(MxBottomSheet), findsOneWidget);
    expect(save(tester).onPressed, isNull);

    await tester.tap(find.text(_en.usersRoleAdminHint));
    await tester.pump();
    expect(save(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(MxButton, _en.usersSave));
    await _settle(tester);

    expect(find.byType(MxBottomSheet), findsNothing);
    expect(find.text(_en.usersNowAdmin('bob@example.com')), findsOneWidget);
    expect(find.text(_en.usersRoleUser), findsNothing);
  });

  libraryTest('the last admin stays, and the sheet says why', (
    tester,
    env,
  ) async {
    await pump(tester, env);
    roles.failNextSet = const LastAdminFailure();

    await tester.tap(find.text('ann@example.com'));
    await _settle(tester);
    await tester.tap(find.text(_en.usersRoleUserHint));
    await tester.pump();
    await tester.tap(find.widgetWithText(MxButton, _en.usersSave));
    await _settle(tester);

    expect(find.byType(MxBottomSheet), findsOneWidget);
    // Said inside the sheet, which a toast would sit behind (final review I2).
    expect(
      find.descendant(
        of: find.byType(MxBottomSheet),
        matching: find.text(_en.usersLastAdmin),
      ),
      findsOneWidget,
    );
  });

  libraryTest('a drag while saving keeps the sheet, so a refusal is still '
      'said (P4 minor M3)', (tester, env) async {
    await pump(tester, env);
    final held = roles.holdSet = Completer<void>();
    roles.failNextSet = const LastAdminFailure();

    await tester.tap(find.text('ann@example.com'));
    await _settle(tester);
    await tester.tap(find.text(_en.usersRoleUserHint));
    await tester.pump();
    await tester.tap(find.widgetWithText(MxButton, _en.usersSave));
    await tester.pump();
    await tester.drag(find.byType(MxBottomSheet), const Offset(0, 500));
    await _settle(tester);
    held.complete();
    await _settle(tester);

    expect(
      find.descendant(
        of: find.byType(MxBottomSheet),
        matching: find.text(_en.usersLastAdmin),
      ),
      findsOneWidget,
    );
  });

  libraryTest('a user gone closes the sheet and says so', (tester, env) async {
    await pump(tester, env);
    roles.users.removeWhere((user) => user.id == 'bob');

    await tester.tap(find.text('bob@example.com'));
    await _settle(tester);
    await tester.tap(find.text(_en.usersRoleAdminHint));
    await tester.pump();
    await tester.tap(find.widgetWithText(MxButton, _en.usersSave));
    await _settle(tester);

    expect(find.byType(MxBottomSheet), findsNothing);
    expect(find.text(_en.usersGone), findsOneWidget);
  });

  libraryTest('no match, and no account at all', (tester, env) async {
    await pump(tester, env);

    await tester.enterText(find.byType(TextField), 'zz');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.text(_en.usersNoMatch('zz')), findsOneWidget);

    roles.users.clear();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.text(_en.usersNone), findsOneWidget);
  });

  libraryTest('offline says so first, with Retry', (tester, env) async {
    roles.failNextList = const OfflineFailure(cause: 'x');
    await pump(tester, env);

    expect(find.text(_en.usersOfflineTitle), findsOneWidget);
    // A network failure keeps the cloud-off glyph; alert is the default
    // for every other failure (critique 2026-09-30 part 1).
    expect(find.byIcon(AppIcons.offline), findsOneWidget);
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(find.text('ann@example.com'), findsOneWidget);
  });

  libraryTest('not an admin: only that is said', (tester, env) async {
    roles.failNextList = const NotAdminFailure(cause: 'x');
    await pump(tester, env);

    expect(find.text(_en.monitoringNotAdminTitle), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}

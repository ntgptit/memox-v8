@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/presentation/screens/users_screen.dart';
import 'package:memox/features/account/presentation/widgets/items/users_entry_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/monitoring_entry_row_widget.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/users_fakes.dart';

// P4 (users spec §3, §4, §6): screen 33, its role sheet, and the Admin
// section of screen 23.

final _en = lookupAppLocalizations(const Locale('en'));

const _me = AccountUser(
  id: 'me',
  email: 'me@example.com',
  isAnonymous: false,
  role: AccountRole.admin,
);

FakeUserRoleRepository _roles() => FakeUserRoleRepository([
  managedUser('ann.nguyen@example.com', role: AccountRole.admin),
  managedUser('bao.tran@example.com'),
  managedUser('chi.le@example.com'),
  managedUser('me@example.com', role: AccountRole.admin),
  managedUser('minh.pham@example.com'),
]);

Widget _settings() => SettingsScreen(
  onOpenTheme: () {},
  onOpenLanguage: () {},
  onOpenReminder: () {},
  onAppOptionsReset: () {},
  onOpenSync: () {},
  adminRows: [
    MonitoringEntryRowWidget(onOpen: () {}),
    UsersEntryRowWidget(onOpen: () {}),
  ],
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// A tap's ink and the pressed overlay fade before the capture.
Future<void> _rest(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 1));

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> capture(
      WidgetTester tester,
      LibraryEnv env,
      Widget screen,
      String name, {
      FakeUserRoleRepository? roles,
      List<Override> overrides = const [],
      Future<void> Function()? before,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          screen,
          brightness,
          overrides: [
            userRoleRepositoryProvider.overrideWithValue(roles ?? _roles()),
            currentAccountProvider.overrideWithValue(_me),
            ...overrides,
          ],
        );
        await _settle(tester);
        await before?.call();
        await expectBoundaryGolden(tester, 'goldens/${name}_$theme.png');
      });
    }

    libraryTest('users, loaded, $theme', (tester, env) async {
      await capture(tester, env, const UsersScreen(), 'users_loaded');
    });

    libraryTest('users, no match, $theme', (tester, env) async {
      await capture(
        tester,
        env,
        const UsersScreen(),
        'users_empty_search',
        before: () async {
          await tester.enterText(find.byType(TextField), 'zz');
          await tester.pump(const Duration(milliseconds: 400));
          await _settle(tester);
        },
      );
    });

    libraryTest('users, offline, $theme', (tester, env) async {
      final roles = _roles()
        ..failNextList = const OfflineFailure(cause: 'golden');
      await capture(
        tester,
        env,
        const UsersScreen(),
        'users_offline',
        roles: roles,
      );
    });

    libraryTest('users, role sheet, $theme', (tester, env) async {
      await capture(
        tester,
        env,
        const UsersScreen(),
        'users_role_sheet',
        before: () async {
          await tester.tap(find.text('bao.tran@example.com'));
          await _settle(tester);
          await _rest(tester);
        },
      );
    });

    libraryTest('users, role sheet changed, $theme', (tester, env) async {
      await capture(
        tester,
        env,
        const UsersScreen(),
        'users_role_sheet_changed',
        before: () async {
          await tester.tap(find.text('bao.tran@example.com'));
          await _settle(tester);
          await tester.tap(find.text(_en.usersRoleAdminHint));
          await _settle(tester);
          await _rest(tester);
        },
      );
    });

    libraryTest('settings, admin rows, $theme', (tester, env) async {
      await capture(
        tester,
        env,
        _settings(),
        'settings_admin_rows',
        overrides: [isAdminProvider.overrideWithValue(true)],
        before: () async {
          await tester.scrollUntilVisible(find.text(_en.usersTitle), 200);
          await _rest(tester);
        },
      );
    });
  }
}

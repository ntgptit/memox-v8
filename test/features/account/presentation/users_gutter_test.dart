import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/presentation/screens/users_screen.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../../support/library_harness.dart';
import '../../../support/users_fakes.dart';

// M3F-19: the search field sits on the screen margin, as the app bar above it.

const _me = AccountUser(
  id: 'me',
  email: 'me@example.com',
  isAnonymous: false,
  role: AccountRole.admin,
);

void main() {
  for (final (width, margin) in [(360.0, 16.0), (700.0, 24.0)]) {
    libraryTest('the Users search field starts and ends on the $margin screen '
        'margin at ${width.toInt()} wide', (tester, env) async {
      final roles = FakeUserRoleRepository([managedUser('bob@example.com')]);
      await pumpLibraryScreen(
        tester,
        env,
        const UsersScreen(),
        overrides: [
          userRoleRepositoryProvider.overrideWithValue(roles),
          currentAccountProvider.overrideWithValue(_me),
        ],
      );
      tester.view.physicalSize = Size(width, 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final field = tester.getRect(find.byType(MxSearchField));
      expect(field.left, margin);
      expect(width - field.right, margin);
    });
  }
}

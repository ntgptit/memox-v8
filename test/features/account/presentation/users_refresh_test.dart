import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/account/presentation/widgets/items/user_row_widget.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/presentation/screens/users_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/users_fakes.dart';

// The pull down has no TalkBack or keyboard equivalent, so the app bar
// offers Refresh, as screen 28 does (closing acceptance 2026-10-18).

final _en = lookupAppLocalizations(const Locale('en'));

const _me = AccountUser(
  id: 'me',
  email: 'me@example.com',
  isAnonymous: false,
  role: AccountRole.admin,
);

final _refreshAction = find.byWidgetPredicate(
  (widget) =>
      widget is MxIconButton && widget.semanticLabel == _en.commonRefresh,
);

MxIconButton _refreshButton(WidgetTester tester) =>
    tester.widget<MxIconButton>(_refreshAction);

void main() {
  libraryTest('Refresh reads the first page again and is off while it runs', (
    tester,
    env,
  ) async {
    final roles = FakeUserRoleRepository([
      managedUser('ann@example.com'),
      managedUser('me@example.com', role: AccountRole.admin),
    ]);
    await pumpLibraryScreen(
      tester,
      env,
      const UsersScreen(),
      overrides: [
        userRoleRepositoryProvider.overrideWithValue(roles),
        currentAccountProvider.overrideWithValue(_me),
      ],
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(userRowTitle('ann@example.com')), findsOneWidget);
    expect(_refreshButton(tester).onPressed, isNotNull);

    roles.users.add(managedUser('bob@example.com'));
    final gate = roles.holdList = Completer<void>();
    await tester.tap(_refreshAction);
    await tester.pump();
    expect(_refreshButton(tester).onPressed, isNull);
    expect(find.text(userRowTitle('ann@example.com')), findsOneWidget);

    gate.complete();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(userRowTitle('bob@example.com')), findsOneWidget);
    expect(_refreshButton(tester).onPressed, isNotNull);
  });
}

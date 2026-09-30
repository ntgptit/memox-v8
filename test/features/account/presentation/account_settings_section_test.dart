import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_settings_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  late int opens;

  setUp(() => opens = 0);

  Widget section() =>
      Scaffold(body: AccountSettingsSectionWidget(onSignIn: () => opens++));

  accountTest('an anonymous device is offered Sign in', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: accountOverrides(world),
    );

    expect(find.text(_en.accountSection.toUpperCase()), findsOneWidget);
    expect(find.text(_en.accountSignInHint), findsOneWidget);
    await tester.tap(find.text(_en.accountSignIn));
    expect(opens, 1);
  });

  accountTest('offline, Sign in waits and says when it will work', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: [...accountOverrides(world), authStateOf(const LocalOnly())],
    );

    expect(find.text(_en.accountSignInLater), findsOneWidget);
    final row = tester.widget<MxSettingsRow>(find.byType(MxSettingsRow));
    expect(row.isEnabled, isFalse);
  });

  accountTest('an attached account shows its email', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: accountOverrides(world),
    );

    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text(_en.accountSignedInHint), findsOneWidget);
  });

  libraryTest('a build that cannot sign in shows nothing', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: [accountCoordinatorProvider.overrideWithValue(null)],
    );

    expect(find.byType(MxSettingsRow), findsNothing);
  });
}

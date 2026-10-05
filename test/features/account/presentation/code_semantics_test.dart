import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';
import '../../../support/library_harness.dart';

// Screen 31 for TalkBack (DEV-168).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  Future<void> pumpCode(
    WidgetTester tester,
    LibraryEnv env,
    AuthWorld world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      CodeScreen(email: 'a@example.com', onSignedIn: () {}),
      overrides: accountOverrides(world),
    );
  }

  accountTest('the lead and the address read as one stop', (
    tester,
    env,
    world,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpCode(tester, env, world);

    expect(
      tester.getSemantics(find.text('a@example.com')),
      isSemantics(label: '${_en.accountCodeSentTo}\na@example.com'),
    );
    handle.dispose();
  });

  accountTest('Resend arrives as one labelled live-region button, so '
      'TalkBack speaks it when the wait ends (final review I1)', (
    tester,
    env,
    world,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpCode(tester, env, world);

    await tester.pump(const Duration(seconds: 60));

    expect(
      tester.getSemantics(find.widgetWithText(MxButton, _en.accountResend)),
      isSemantics(label: _en.accountResend, isButton: true, isLiveRegion: true),
    );
    handle.dispose();
  });
}

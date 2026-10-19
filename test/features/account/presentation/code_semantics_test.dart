import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/email_text.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/account_harness.dart';

// Screen 31 for TalkBack (DEV-168).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  CodeScreen screen() => CodeScreen(email: 'a@example.com', onSignedIn: () {});

  accountTest('the lead and the address read as one stop', (
    tester,
    env,
    world,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpCode(tester, env, world, screen());

    // The address breaks before its domain; TalkBack skips the zero-width
    // space (audit 2026-10-19, G5).
    expect(
      tester.getSemantics(find.text(wrappableEmail('a@example.com'))),
      isSemantics(
        label: '${_en.accountCodeSentTo}\n${wrappableEmail('a@example.com')}',
      ),
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
    await pumpCode(tester, env, world, screen());

    await tester.pump(const Duration(seconds: 60));

    expect(
      tester.getSemantics(find.widgetWithText(MxButton, _en.accountResend)),
      isSemantics(label: _en.accountResend, isButton: true, isLiveRegion: true),
    );
    handle.dispose();
  });
}

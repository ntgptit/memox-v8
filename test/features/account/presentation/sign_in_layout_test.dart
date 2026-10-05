import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

// Screen 30's layout balance (spec 2026-10-05-sign-in-layout-balance, DEV-166).

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  accountTest('the email field rests on the outline edge (2026-10-05 L1)', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      SignInScreen(onCodeSent: (_) {}, onSignedIn: () {}),
      overrides: accountOverrides(world),
    );

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
      AppColorSchemes.light.outline,
    );
  });

  accountTest('the way-out dialog leaves 16 dp between its banner and the '
      'actions, as a dialog without a note does (2026-10-05 L3)', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await pumpLibraryScreen(
      tester,
      env,
      SignInScreen(
        purpose: SignInPurpose.reauth,
        onCodeSent: (_) {},
        onSignedIn: () {},
        onLeftAccount: () {},
      ),
      overrides: accountOverrides(world),
    );
    await _settle(tester);
    await tester.tap(find.text(_en.accountContinueWithoutThis));
    await _settle(tester);

    final painted = find
        .descendant(
          of: find.byType(MxInlineBanner),
          matching: find.byType(DecoratedBox),
        )
        .first;
    final cancel = find.descendant(
      of: find.byType(MxDialog),
      matching: find.widgetWithText(MxButton, _en.commonCancel),
    );
    expect(
      tester.getTopLeft(cancel).dy - tester.getBottomLeft(painted).dy,
      closeTo(16, 0.5),
    );
  });

  accountTest('while the keyboard is up the footer keeps Send code alone '
      '(DEV-168)', (tester, env, world) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await pumpLibraryScreen(
      tester,
      env,
      SignInScreen(onCodeSent: (_) {}, onSignedIn: () {}),
      overrides: accountOverrides(world),
    );

    expect(find.widgetWithText(MxButton, _en.accountSendCode), findsOneWidget);
    expect(find.text(_en.accountContinueGoogle), findsNothing);

    tester.view.resetViewInsets();
    await tester.pump();
    expect(find.text(_en.accountContinueGoogle), findsOneWidget);
  });
}

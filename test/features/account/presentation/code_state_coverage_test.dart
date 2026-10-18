import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

// The States rows of screen 31 (Code) whose detail file cites no executed
// test: "resend failed".

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final (name, problem, message) in <(String, Failure, SignInProblem)>[
    ('rate-limited', const RateLimitedFailure(), SignInProblem.rateLimited),
    ('failed', const ServerFailure(cause: 'fake 5xx'), SignInProblem.failed),
  ]) {
    accountTest('resend failed: a $name resend shows its problem under the '
        'field and leaves Resend code available at once', (
      tester,
      env,
      world,
    ) async {
      await world.coordinator.requestCode('a@example.com');
      await pumpLibraryScreen(
        tester,
        env,
        CodeScreen(email: 'a@example.com', onSignedIn: () {}),
        overrides: accountOverrides(world),
      );
      await tester.pump(const Duration(seconds: 60));

      world.gateway.failNextRequest = problem;
      await tester.tap(find.text(_en.accountResend));
      await _settle(tester);

      expect(find.text(signInProblemText(_en, message)), findsOneWidget);
      expect(find.text(_en.accountCodeResent), findsNothing);
      // No new wait: the button is there to press again.
      expect(find.text(_en.accountResendIn('1:00')), findsNothing);
      final resend = find.widgetWithText(MxButton, _en.accountResend);
      expect(resend, findsOneWidget);
      expect(tester.widget<MxButton>(resend).isLoading, isFalse);
      expect(tester.widget<MxButton>(resend).onPressed, isNotNull);

      await tester.tap(find.text(_en.accountResend));
      await _settle(tester);

      expect(find.text(_en.accountCodeResent), findsOneWidget);
      expect(find.text(_en.accountResendIn('1:00')), findsOneWidget);
    });
  }

  accountTest('resend failed: an offline resend says it is offline and leaves '
      'Resend code available', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      CodeScreen(email: 'a@example.com', onSignedIn: () {}),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));

    world.server.offline = true;
    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);

    expect(
      find.text(signInProblemText(_en, SignInProblem.offline)),
      findsOneWidget,
    );
    expect(find.text(_en.accountResendIn('1:00')), findsNothing);
    expect(find.widgetWithText(MxButton, _en.accountResend), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../../support/account_harness.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

MxButton _button(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

void main() {
  late List<String> codesSent;
  late int signIns;

  SignInScreen screen() =>
      SignInScreen(onCodeSent: codesSent.add, onSignedIn: () => signIns++);

  setUp(() {
    codesSent = [];
    signIns = 0;
  });

  accountTest('the two ways sit in the footer, Send code the one fill, and '
      'the form leads with its title', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    Finder inFooter(String text) => find.descendant(
      of: find.byType(MxFooterBar),
      matching: find.text(text),
    );
    expect(inFooter(_en.accountSendCode), findsOneWidget);
    expect(inFooter(_en.accountContinueGoogle), findsOneWidget);
    expect(_button(tester, _en.accountSendCode).tone, MxButtonTone.primary);
    expect(
      _button(tester, _en.accountContinueGoogle).tone,
      MxButtonTone.outline,
    );
    expect(find.text(_en.accountSignIn), findsOneWidget);
    expect(find.text(_en.accountEmail), findsOneWidget);
    expect(find.text(_en.accountEmailHint), findsOneWidget);
    expect(find.text(_en.accountOfflineNote), findsNothing);
  });

  accountTest('the title names the route for TalkBack', (
    tester,
    env,
    world,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    final node = tester.getSemantics(find.text(_en.accountSignIn));
    expect(node.hasFlag(SemanticsFlag.namesRoute), isTrue);
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    handle.dispose();
  });

  accountTest('linking focuses the empty address', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  accountTest('a re-auth whose address is not known yet shows no eyebrow, '
      'then shows it when it lands', (tester, env, world) async {
    await refuseSession(world);
    final email = ValueNotifier<String?>(null);
    addTearDown(email.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      ValueListenableBuilder<String?>(
        valueListenable: email,
        builder: (_, value, _) => SignInFormWidget(
          purpose: SignInPurpose.reauth,
          initialEmail: value,
          onCodeSent: (_) {},
        ),
      ),
      overrides: accountOverrides(world),
    );
    expect(find.text('a@example.com'), findsNothing);

    email.value = 'a@example.com';
    await tester.pump();

    expect(
      find.text('${_en.accountSignedOutLabel.toUpperCase()} · a@example.com'),
      findsOneWidget,
    );
  });

  accountTest('an address gets a code, and the code screen is next', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(codesSent, ['a@example.com']);
  });

  accountTest('a mistyped address is said under the field, and nothing is '
      'sent', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.text(_en.accountEmailInvalid), findsOneWidget);
    expect(codesSent, isEmpty);
    expect(world.server.sentCodes, isEmpty);
  });

  accountTest('Google attaches the account, says so and leaves', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);

    expect(signIns, 1);
    expect(find.text(_en.accountSignedInAs('g@example.com')), findsOneWidget);
  });

  accountTest('while Google signs in, the link form never shows the offline '
      'caption (final review F2)', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    final held = world.api.holdMe = Completer<void>();

    await tester.tap(find.text(_en.accountContinueGoogle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(_en.accountOfflineNote), findsNothing);
    expect(_button(tester, _en.accountContinueGoogle).isLoading, isTrue);

    held.complete();
    world.api.holdMe = null;
    await _settle(tester);
    expect(signIns, 1);
  });

  accountTest("another account's address asks to merge", (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: 'b@example.com');
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'b@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.byType(MergeChoiceSheetWidget), findsOneWidget);
  });

  accountTest('offline says that nothing changed', (tester, env, world) async {
    world.network.goOffline();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.text(_en.accountOffline), findsOneWidget);
  });

  accountTest('not ready to link: the form waits and says why', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), authStateOf(const LocalOnly())],
    );

    expect(_button(tester, _en.accountSendCode).onPressed, isNull);
    expect(_button(tester, _en.accountContinueGoogle).onPressed, isNull);
    expect(
      find.descendant(
        of: find.byType(MxFooterBar),
        matching: find.text(_en.accountOfflineNote),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.accountOfflineNote), findsOneWidget);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });

  group('reauth', () {
    late int left;

    setUp(() => left = 0);

    SignInScreen reauth() => SignInScreen(
      purpose: SignInPurpose.reauth,
      onCodeSent: codesSent.add,
      onSignedIn: () => signIns++,
      onLeftAccount: () => left++,
    );

    accountTest('re-auth names the account, says why, and keeps its way out '
        'in the body, out of the footer', (tester, env, world) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );
      await _settle(tester);

      expect(find.text(_en.accountReauthTitle), findsOneWidget);
      expect(find.text(_en.accountReauthLine), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MxFooterBar),
          matching: find.text(_en.accountContinueWithoutThis),
        ),
        findsNothing,
      );
      expect(find.text(_en.accountContinueWithoutThis), findsOneWidget);
      // S9: the way out sits 32 under the address field.
      final wayOut = find.widgetWithText(
        MxButton,
        _en.accountContinueWithoutThis,
      );
      final field = find.byType(MxTextField);
      expect(
        tester.getTopLeft(wayOut).dy - tester.getBottomLeft(field).dy,
        AppSpacing.major,
      );
    });

    accountTest('the reauth line, and the last address filled in', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      expect(find.text(_en.accountReauthLine), findsOneWidget);
      expect(
        find.text('${_en.accountSignedOutLabel.toUpperCase()} · a@example.com'),
        findsOneWidget,
      );
      expect(_button(tester, _en.accountSendCode).onPressed, isNotNull);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });

    accountTest('another address with changes unsent asks, then sends', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      await tester.enterText(find.byType(TextField), 'b@example.com');
      await tester.tap(find.text(_en.accountSendCode));
      await _settle(tester);
      expect(find.text(_en.accountUnsentTitle(2)), findsOneWidget);

      await tester.tap(find.widgetWithText(MxButton, _en.accountUnsentConfirm));
      await _settle(tester);
      expect(codesSent, ['b@example.com']);
    });

    accountTest('a cancelled loss forgets the Google account, so the next '
        'press picks again (final review I1)', (tester, env, world) async {
      await refuseSession(world);
      world.gateway.google = const GoogleCredential(
        idToken: 'other',
        email: 'other@example.com',
      );
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );
      await _settle(tester);

      await tester.tap(find.text(_en.accountContinueGoogle));
      await _settle(tester);
      expect(find.text(_en.accountUnsentTitle(2)), findsOneWidget);
      await tester.tap(find.text(_en.commonCancel));
      await _settle(tester);

      world.gateway.google = const GoogleCredential(
        idToken: 'same',
        email: 'a@example.com',
      );
      await tester.tap(find.text(_en.accountContinueGoogle));
      await _settle(tester);

      expect(find.text(_en.accountUnsentTitle(2)), findsNothing);
      expect(signIns, 1);
    });

    accountTest('Continue without an account names the changes it loses '
        '(final review I2)', (tester, env, world) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );
      await _settle(tester);

      await tester.tap(find.text(_en.accountContinueWithoutThis));
      await _settle(tester);

      expect(find.text(_en.accountUnsentBody(2)), findsOneWidget);
    });

    accountTest('Continue without an account asks, then leaves the account', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      await tester.tap(find.text(_en.accountContinueWithoutThis));
      await _settle(tester);
      expect(
        find.text(_en.accountWithoutBody('a@example.com')),
        findsOneWidget,
      );
      // The dialog's confirm.
      await tester.tap(
        find.descendant(
          of: find.byType(MxDialog),
          matching: find.widgetWithText(MxButton, _en.accountWithoutConfirm),
        ),
      );
      await _settle(tester);

      expect(left, 1);
      expect(world.state, isNot(isA<ReauthRequired>()));
    });
  });
}
